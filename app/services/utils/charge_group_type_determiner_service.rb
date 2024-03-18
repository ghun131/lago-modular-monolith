# frozen_string_literal: true

module Utils
  class ChargeGroupTypeDeterminerService < BaseService
    def initialize(charge_group)
      @charge_group = charge_group
      super(nil)
    end

    def call
      result.charge_group_type = charge_group_type
    end

    private

    attr_reader :charge_group

    def charge_group_type
      return Constants::CHARGE_GROUP_TYPES[:PACKAGES_GROUP] if all_charges_are_package_group?
      return Constants::CHARGE_GROUP_TYPES[:PACKAGE_TIMEBASED_GROUP] if has_one_timebased_charge?

      Constants::CHARGE_GROUP_TYPES[:UNKNOWN]
    end

    def has_one_timebased_charge?
      charge_group.charges.timebased.count == 1
    end

    def all_charges_are_package_group?
      charge_group.charges.count == charge_group.charges.package_group.count
    end
  end
end
