# frozen_string_literal: true
module Hyrax
  module Identifier
    class Dispatcher
      ##
      # @!attribute [rw] registrar
      #   @return [Hyrax::Identifier::Registrar]
      attr_accessor :registrar

      ##
      # @param registrar [Hyrax::Identifier::Registrar]
      def initialize(registrar:)
        @registrar = registrar
      end

      class << self
        ##
        # @param type           [Symbol]
        # @param registrar_opts [Hash]
        # @option registrar_opts [Hyrax::Identifier::Builder] :builder
        #
        # @return [Hyrax::Identifier::Dispatcher] a dispatcher with an registrar for the
        #   given type
        # @see IdentifierRegistrar.for
        def for(type, **registrar_opts)
          new(registrar: Hyrax::Identifier::Registrar.for(type, **registrar_opts))
        end
      end

      ##
      # Assigns an identifier to the object.
      #
      # This involves two steps:
      #   - Registering the identifier with the registrar service via `registrar`.
      #   - Storing the new identifier on the object, in the provided `attribute`.
      #
      # @note the attribute for identifier storage must be multi-valued, and will
      #  be overwritten during assignment.
      #
      # @param attribute [Symbol] the attribute in which to store the identifier.
      #   This attribute will be overwritten during assignment.
      # @param object    [ActiveFedora::Base, Hyrax::Resource] the object to assign an identifier.
      #
      # @return [ActiveFedora::Base, Hyrax::Resource] object
      def assign_for(object:, attribute: :identifier)
        record = registrar.register!(object: object)
        object.public_send("#{attribute}=".to_sym, Array.wrap(record.identifier))
        object
      end

      ##
      # Assigns an identifier and saves the object.
      #
      # @see #assign_for
      def assign_for!(object:, attribute: :identifier)
        result = assign_for(object: object, attribute: attribute)

        case result
        when Valkyrie::Resource
          Hyrax.persister.save(resource: result)
        else
          result.save
          result
        end
      end
    end
  end
end
