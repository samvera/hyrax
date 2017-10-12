module Hyrax
  module Actors
    class Environment
      # @param [ActiveFedora::Base] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize(curation_concern, current_ability, attributes)
        @curation_concern = curation_concern
        @current_ability = current_ability
        @attributes = attributes.to_h.with_indifferent_access
      end

      attr_reader :curation_concern, :current_ability, :attributes

      def change_set_persister
        Hyrax::ChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter)
      end

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end
    end
  end
end
