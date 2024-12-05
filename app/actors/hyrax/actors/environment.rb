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
        # This is no longer allowed because keys in attributes haven't been permitted yet
        # @attributes = attributes.to_h.with_indifferent_access
        #
        attributes.permit! if attributes.class == ActionController::Parameters
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
