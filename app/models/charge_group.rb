# frozen_string_literal: true

class ChargeGroup < ApplicationRecord
  include PaperTrailTraceable
  include Discard::Model
  self.discard_column = :deleted_at

  belongs_to :plan, -> { with_discarded }, touch: true

  has_many :charges, dependent: :destroy
  has_many :usage_charge_groups, dependent: :destroy

  default_scope -> { kept }
end
