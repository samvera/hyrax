module Hyrax
  module Actors
    class Environment
      # @param [Valkyrie::ChangeSet] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize(change_set, current_ability, attributes)
        @change_set = change_set
        @current_ability = current_ability
        @attributes = attributes.to_h.with_indifferent_access
      end

      attr_reader :change_set, :current_ability, :attributes, :change_set

      def change_set_persister
        Hyrax::ChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter)
      end

      delegate :resource, to: :change_set
      alias curation_concern resource

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end
    end
  end
end
