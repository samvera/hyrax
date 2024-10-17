# frozen_string_literal: true
module Hyrax
  module Forms
    module Admin
      class CollectionTypeForm
        include ActiveModel::Model
        attr_accessor :collection_type
        validates :title, presence: true

        delegate :title, :description, :brandable, :discoverable, :nestable, :sharable, :share_applies_to_new_works,
                 :require_membership, :allow_multiple_membership, :assigns_workflow,
                 :assigns_visibility, :id, :collection_type_participants, :persisted?,
                 :admin_set?, :user_collection?, :badge_color, :collections?, to: :collection_type

        ##
        # @return [Boolean]
        def all_settings_disabled?
          collections? || admin_set? || user_collection?
        end

        ##
        # @return [Boolean]
        def share_options_disabled?
          all_settings_disabled? || !sharable
        end
      end
    end
  end
end
