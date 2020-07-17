# frozen_string_literal: true
module Hyrax
  module Identifier
    class Registrar
      class << self
        ##
        # @param type [Symbol]
        # @param opts [Hash]
        # @option opts [Hyrax::Identifier::Builder] :builder
        #
        # @return [Hyrax::Identifier::Registrar] a registrar for the given type
        def for(type, **opts)
          return Hyrax.config.identifier_registrars[type].new(**opts) if Hyrax.config.identifier_registrars.include?(type)
          raise ArgumentError, "Hyrax::Identifier::Registrar not found to handle #{type}"
        end
      end

      ##
      # @!attribute builder [rw]
      #   @return [Hyrax::Identifier::Builder]
      attr_accessor :builder

      ##
      # @param builder [Hyrax::Identifier::Builder]
      def initialize(builder:)
        @builder = builder
      end

      ##
      # @abstract
      #
      # @param object [#id]
      #
      # @return [#identifier]
      # @raise [NotImplementedError] when the method is abstract
      def register!(*)
        raise NotImplementedError
      end
    end
  end
end
