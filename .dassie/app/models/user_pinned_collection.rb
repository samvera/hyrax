class UserPinnedCollection < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  validates :user_id, presence: true 
  validates :collection_id, presence: true 
end
