require 'spicy_wings/active_fedora_converter'

module SpicyWings
  module Pcdm
    module ObjectValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include SpicyWings::Pcdm::PcdmValkyrieBehavior
      end

      ##
      # @return [Boolean] whether this instance is a PCDM Object.
      def pcdm_object?
        true
      end

      ##
      # @return [Boolean] whether this instance is a PCDM Collection.
      def pcdm_collection?
        false
      end

      # TODO: Add translated methods
    end
  end
end
