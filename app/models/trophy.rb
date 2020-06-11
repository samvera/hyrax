# frozen_string_literal: true
class Trophy < ActiveRecord::Base
  validate :count_within_limit, on: :create

  def count_within_limit
    return if Trophy.where(user_id: user_id).count < 5
    errors.add(:base, "Exceeded trophy limit")
  end
end
