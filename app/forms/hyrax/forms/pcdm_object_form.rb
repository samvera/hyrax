# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # A form for PCDM objects: resources which have collection relationships and
    # generally resemble +Hyrax::Work+.
    class PcdmObjectForm < Hyrax::Forms::ResourceForm
      include Hyrax::FormFields(:core_metadata)

      property :on_behalf_of
      property :proxy_depositor

      # pcdm relationships
      property :admin_set_id, prepopulator: ->(_opts) { self.admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s }
      property :member_ids, default: [], type: Valkyrie::Types::Array
      property :member_of_collection_ids, default: [], type: Valkyrie::Types::Array
      property :member_of_collections_attributes, virtual: true, populator: :in_collections_populator
      validates_with CollectionMembershipValidator

      property :representative_id, type: Valkyrie::Types::String
      property :thumbnail_id, type: Valkyrie::Types::String
      property :rendering_ids, default: [], type: Valkyrie::Types::Array

      # backs the child work search element;
      # @todo: look for a way for the view template not to depend on this
      property :find_child_work, default: nil, virtual: true

      private

      def in_collections_populator(fragment:, **_options)
        adds = []
        deletes = []
        fragment.each do |_, h|
          if h["_destroy"] == "true"
            deletes << Valkyrie::ID.new(h["id"])
          else
            adds << Valkyrie::ID.new(h["id"])
          end
        end

        self.member_of_collection_ids = ((member_of_collection_ids + adds) - deletes).uniq
      end
    end
  end
end
