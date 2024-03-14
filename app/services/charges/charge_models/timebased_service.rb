# frozen_string_literal: true

module Charges
  module ChargeModels
    class TimebasedService < Charges::ChargeModels::BaseService
      protected

      def compute_amount
        per_package_unit_amount
      end

      def unit_amount
        return 0 if paid_units <= 0

        compute_amount / paid_units
      end

      def different_in_minutes
        @different_in_minutes ||= units
      end

      def per_block_time_in_minutes
        @per_block_time_in_minutes ||= properties['block_time_in_minutes']
      end

      def per_package_unit_amount
        @per_package_unit_amount ||= if is_in_group_charge?
          per_group_package_unit_amount
        else
          BigDecimal(properties['amount'])
        end
      end

      def paid_units
        @paid_units ||= units
      end

      private

      def is_in_group_charge?
        charge.charge_group_id.present?
      end

      def per_group_package_unit_amount
        @per_group_package_unit_amount ||= BigDecimal(charge.charge_group.properties['amount'])
      end
    end
  end
end
