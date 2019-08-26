# frozen_string_literal: true
module Wings
  module Valkyrie
    class Persister
      attr_reader :adapter
      extend Forwardable
      def_delegator :adapter, :resource_factory

      # @param adapter [Wings::Valkyrie::MetadataAdapter] The adapter which holds the resource_factory for this persister.
      # @note Many persister methods are part of Valkyrie's public API, but instantiation itself is not
      def initialize(adapter:)
        @adapter = adapter
      end

      # Persists a resource using ActiveFedora
      # @param [Valkyrie::Resource] resource
      # @return [Valkyrie::Resource] the persisted/updated resource
      def save(resource:)
        return save_file(file_metadata: resource) if resource.is_a? Hyrax::FileMetadata
        af_object = resource_factory.from_resource(resource: resource)
        af_object.save!
        resource_factory.to_resource(object: af_object)
      rescue ActiveFedora::RecordInvalid => err
        raise FailedSaveError.new(err.message, obj: af_object)
      end

      def save_file(file_metadata:)
        # This is a no-op when the file is being created or updated through the FileActor.
        # There may be other scenarios where something needs to happen here.

        # TODO: SKIP for now, but potentially need to...
        #   find existing af File
        #   convert file_metadata resource into af File metadata
        #   save af File
      end

      # Persists a resource using ActiveFedora
      # @param [Valkyrie::Resource] resource
      # @return [Valkyrie::Resource] the persisted/updated resource
      def save_all(resources:)
        resources.map do |resource|
          save(resource: resource)
        end
      end

      # Deletes a resource persisted using ActiveFedora
      # @param [Valkyrie::Resource] resource
      # @return [Valkyrie::Resource] the deleted resource
      def delete(resource:)
        af_object = ActiveFedora::Base.new
        af_object.id = resource.alternate_ids.first.to_s
        af_object.delete
      end

      # Deletes all resources from Fedora and Solr
      def wipe!
        Hyrax::SolrService.delete_by_query("*:*")
        Hyrax::SolrService.commit
        ActiveFedora::Cleaner.clean!
      end

      class FailedSaveError < RuntimeError
        attr_accessor :obj

        def initialize(msg = nil, obj:)
          self.obj = obj
          super(msg)
        end
      end
    end
  end
end
