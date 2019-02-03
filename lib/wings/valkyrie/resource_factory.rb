# frozen_string_literal: true

require 'wings/active_fedora_converter'

module Wings
  module Valkyrie
    ##
    # This class provides two-way mapping between `ActiveFedora::Base` and
    # `Valkyrie::Resource` models.
    #
    # @see Wings::ActiveFedoraConverter
    # @see Wings::Valkyrizable
    class ResourceFactory
      ##
      # @!attribute [r] adapter
      #   @return [MetadataAdapter]
      attr_reader :adapter

      delegate :id, to: :adapter, prefix: true

      ##
      # @param [MetadataAdapter] adapter
      def initialize(adapter:)
        @adapter = adapter
      end

      ##
      # @param object [ActiveFedora::Base] AF record to be converted.
      #
      # @return [Valkyrie::Resource] Model representation of the AF record.
      def to_resource(object:)
        object.valkyrie_resource
      end

      ##
      # @param resource [Valkyrie::Resource] Model to be converted to ActiveRecord.
      #
      # @return [ActiveFedora::Base] ActiveFedora
      #   resource for the Valkyrie resource.
      def from_resource(resource:)
        ActiveFedoraConverter.new(resource: resource).convert
      end
    end
  end
end
