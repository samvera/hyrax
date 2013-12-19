class Trophy < ActiveRecord::Base
  validate :count_within_limit, :on => :create

  def count_within_limit
    if Trophy.where(user_id:self.user_id).count >= 5
      errors.add(:base, "Exceeded trophy limit")
    end
  end
end

