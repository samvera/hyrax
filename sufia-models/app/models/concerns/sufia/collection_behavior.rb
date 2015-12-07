module Sufia
  module CollectionBehavior
    extend ActiveSupport::Concern

    included do
      before_save :update_permissions
      validates :title, presence: true
    end

    def update_permissions
      self.visibility = "open"
    end
  end
end
