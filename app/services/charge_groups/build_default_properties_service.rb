# frozen_string_literal: true

module ChargeGroups
  class BuildDefaultPropertiesService < BaseService
    def call
      default_charge_group_properties
    end

    private

    def default_charge_group_properties
      { 'amount': '0' }
    end
  end
end
