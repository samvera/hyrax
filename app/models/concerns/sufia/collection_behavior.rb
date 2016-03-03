module Sufia
  module CollectionBehavior
    extend ActiveSupport::Concern

    included do
      before_save :update_permissions
    end

    def update_permissions
      self.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end
end
