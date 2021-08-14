# frozen_string_literal: true
module Hyrax
  module Fixity
    ##
    # Implements Hyrax's FixityService interface for a generic Valkyrie adapter.
    class ValkyrieFixityService
      ##
      # @!attribute [rw] target
      attr_accessor :target

      ##
      # @param [#to_s] target id for the object to check fixity for
      def initialize(target_id)
        @target = target_id
      end

      ##
      # @todo implement me
      # @return [Boolean]
      def check
        raise NotImplementedError
      end

      ##
      # @todo implement me
      # @return [String]
      def expected_message_digest
        raise NotImplementedError
      end
    end
  end
end
