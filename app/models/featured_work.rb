# frozen_string_literal: true
class FeaturedWork < ActiveRecord::Base
  FEATURE_LIMIT = 5
  validate :count_within_limit, on: :create
  validates :order, inclusion: { in: proc { 0..FEATURE_LIMIT } }

  default_scope { order(:order) }

  def count_within_limit
    return if FeaturedWork.can_create_another?
    errors.add(:base, "Limited to #{FEATURE_LIMIT} featured works.")
  end

  attr_accessor :presenter

  class << self
    def can_create_another?
      FeaturedWork.count < FEATURE_LIMIT
    end
  end
end
