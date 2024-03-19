# frozen_string_literal: true

module TimebasedEvents
  module PackageTimebasedGroup
    class CreateService < BaseService
      def initialize(event, sync: false)
        @event = event
        @sync = sync
        super(nil)
      end

      def call
        timebased_event = build_timebased_event
        timebased_event.save!

        process_renewal

        if (current_package_count = event.current_package_count) > 1
          increase_current_package_count(current_package_count)
          update_usage_charge_group(current_package_count)
        end

        result.timebased_event = timebased_event

        result
      end

      def process_timebased_event?
        matching_grouped_charge_model? && block_time_elapsed?
      end

      private

      attr_accessor :event, :sync

      delegate :organization, to: :event

      def block_time_elapsed?
        latest_subscription_renewal_event_within_block_time(block_time_in_minutes).blank?
      end

      def latest_subscription_renewal_event_within_block_time(block_time_in_minutes)
        @latest_subscription_renewal_event_within_block_time ||= TimebasedEvent
          .where(organization_id: organization.id)
          .where(external_subscription_id: subscription.external_id)
          .where('timestamp >= ?', event.timestamp - block_time_in_minutes.minutes)
          .order(timestamp: :desc)
          .first
      end

      def block_time_in_minutes
        timebased_charge.properties&.fetch('block_time_in_minutes')
      end

      def matching_grouped_charge_model?
        return false if matching_charge.blank?

        matching_charge.charge_model == 'package_group' && is_grouped_with_timebased_charge?
      end

      def subscription
        @subscription ||= Subscription.find_by(external_id: event.external_subscription_id)
      end

      def build_timebased_event
        TimebasedEvent.new(
          organization:,
          external_customer_id: event.external_customer_id,
          external_subscription_id: event.external_subscription_id,
          metadata: event.metadata,
          timestamp: Time.zone.at(event.timestamp),
        )
      end

      def matching_charge
        return nil if (plan = subscription&.plan).blank?

        @matching_charge ||= Charge.where(
          charge_model: :package_group,
          billable_metric_id: matching_billable_metric.id,
          plan_id: plan.id,
        ).first
      end

      def is_grouped_with_timebased_charge?
        timebased_charge.present?
      end

      def timebased_charge
        @timebased_charge ||= matching_charge.charge_group.charges.find_by(charge_model: 'timebased')
      end

      def process_renewal
        if sync
          renewal_result = Invoices::CreatePayInAdvanceSyncChargeJob
            .perform_now(charge: timebased_charge, event:, timestamp: event.timestamp)

          renewal_result unless renewal_result.success?
          return
        end

        Invoices::CreatePayInAdvanceChargeJob
          .perform_later(charge: timebased_charge, event:, timestamp: event.timestamp)
      end

      def increase_current_package_count(current_package_count)
        new_package_count = current_package_count + 1
        event.update!(current_package_count: new_package_count)
      end

      def update_usage_charge_group(current_package_count)
        usage_charge_group = UsageChargeGroup.find_by(
          charge_group_id: matching_charge.charge_group.id,
          subscription_id: subscription.id,
        )

        return unless usage_charge_group

        available_group_usage = initialize_available_group_usage(usage_charge_group)

        usage_charge_group.update!(
          available_group_usage:,
          current_package_count: current_package_count + 1,
        )
      end

      def matching_billable_metric
        @matching_billable_metric ||= organization.billable_metrics.find_by(code: event.code)
      end

      def initialize_available_group_usage
        available_group_usage = {}
        matching_charge.charge_group.charges.package_group.each do |child_charge|
          available_group_usage[child_charge.billable_metric_id] = child_charge.properties['package_size']
        end

        available_group_usage
      end
    end
  end
end
