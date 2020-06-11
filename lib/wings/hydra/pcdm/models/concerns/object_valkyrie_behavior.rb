# frozen_string_literal: true
require 'wings/active_fedora_converter'

module Wings
  module Pcdm
    module ObjectValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include Wings::Pcdm::PcdmValkyrieBehavior
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
