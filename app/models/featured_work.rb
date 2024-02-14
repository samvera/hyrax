# frozen_string_literal: true
class FeaturedWork < ActiveRecord::Base
  ##
  # @!group Class Attributes
  #
  # @!attribute feature_limit [r|w]
  #   @return [Integer]
  class_attribute :feature_limit, default: 5
  # @!endgroup Class Attributes
  ##

  validate :count_within_limit, on: :create
  validates :order, inclusion: { in: proc { 0..feature_limit } }

  default_scope { order(:order) }

  def count_within_limit
    return if FeaturedWork.can_create_another?
    errors.add(:base, "Limited to #{feature_limit} featured works.")
  end

  attr_accessor :presenter

  class << self
    def can_create_another?
      FeaturedWork.count < feature_limit
    end
  end
end
