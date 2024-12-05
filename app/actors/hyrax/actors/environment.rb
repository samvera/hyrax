# frozen_string_literal: true
module Hyrax
  module Actors
    class Environment
      # @param [ActiveFedora::Base] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize(curation_concern, current_ability, attributes)
        @curation_concern = curation_concern
        @current_ability = current_ability

        # TODO: how to safely permit a variable list of attributes if we don't know them in advance?
        # It seems as though most attributes arriving here are already a hash, probably because
        # they were handled and permitted via a form(?).  But if they are posted directly to the
        # controller, the attributes arrive as ActionController::Parameters.
        # So, this is no longer allowed because keys throughout structure haven't been permitted yet:
        # @attributes = attributes.to_h.with_indifferent_access
        #
        # attributes.permit! if attributes.class == ActionController::Parameters
        @attributes = attributes.to_h.with_indifferent_access
      end

      ##
      # @!attribute [rw] attributes
      #   @return [Hash]
      # @!attribute [rw] curation_concern
      #   @return [Object]
      # @!attribute [rw] current_ability
      #   @return [Hyrax::Ability]
      attr_accessor :attributes, :curation_concern, :current_ability

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end
    end
  end
end
