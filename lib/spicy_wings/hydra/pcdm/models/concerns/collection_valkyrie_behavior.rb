require 'spicy_wings/hydra/pcdm/models/concerns/pcdm_valkyrie_behavior'

module SpicyWings
  module Pcdm
    module CollectionValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include SpicyWings::Pcdm::PcdmValkyrieBehavior
      end

      ##
      # @return [Boolean] whether this instance is a PCDM Object.
      def pcdm_object?
        false
      end

      ##
      # @return [Boolean] whether this instance is a PCDM Collection.
      def pcdm_collection?
        true
      end

      # TODO: Add translated methods
    end
  end
end
