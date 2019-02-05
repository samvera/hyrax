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
        @actor_storage = {}
      end

      attr_reader :curation_concern, :current_ability, :attributes

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end

      def store(actor, key, value)
        store_for(actor)[key] = value
      end

      def retrieve(actor, key)
        store_for(actor)[key]
      end

      private

        def store_for(actor)
          @actor_storage[actor] ||= {}
        end
    end
  end
end
