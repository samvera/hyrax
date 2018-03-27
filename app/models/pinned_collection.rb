class PinnedCollection < ActiveRecord::Base
  validates :collection_id, :user_id, :status, presence: true
  attr_accessor :collection_id, :user_id, :status
end