# frozen_string_literal: true
class UserPinnedCollection < ActiveRecord::Base
  belongs_to :user
  validates :user_id, :collection_id, presence: true
  validates :collection_id, uniqueness: { scope: :user_id }
end
