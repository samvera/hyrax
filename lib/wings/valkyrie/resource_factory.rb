# frozen_string_literal: true

module Wings
  module Valkyrie
    class ResourceFactory
      attr_reader :adapter
      delegate :id, to: :adapter, prefix: true

      # @param [MetadataAdapter] adapter
      def initialize(adapter:)
        @adapter = adapter
      end

      # @param object [ActiveFedora::Base] AF
      #   record to be converted.
      # @return [Valkyrie::Resource] Model representation of the AF record.
      def to_resource(object:)
        object.valkyrie_resource
      end

      # @param resource [Valkyrie::Resource] Model to be converted to ActiveRecord.
      # @return [ActiveFedora::Base] ActiveFedora
      #   resource for the Valkyrie resource.
      def from_resource(resource:)
        # af_object = resource.fedora_model.new(af_attributes(resource))

        # hack
        af_object = GenericWork.new(af_attributes(resource))
        # end of hack

        afid = af_id(resource)
        af_object.id = afid unless afid.empty?
        af_object
      end

      private

        def af_attributes(resource)
          hash = resource.to_h
          hash.delete(:internal_resource)
          hash.delete(:new_record)
          hash.delete(:id)
          hash.delete(:alternate_ids)
          # Deal with these later
          hash.delete(:created_at)
          hash.delete(:updated_at)
          hash.compact
        end

        def af_id(resource)
          resource.id.to_s
        end

        def translate_resource(resource)
          hash = resource.to_h
          hash.delete(:internal_resource)
          hash.delete(:new_record)
          hash.delete(:id)

          resource.fedora_model.new(hash.compact)
        end
    end
  end
end
