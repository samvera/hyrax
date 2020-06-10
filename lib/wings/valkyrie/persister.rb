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

        check_lock_tokens(af_object: af_object, resource: resource)

        af_object.save!
        resource_factory.to_resource(object: af_object)
      rescue ActiveFedora::RecordInvalid => err
        raise FailedSaveError.new(err.message, obj: af_object)
      end

      def save_file(file_metadata:)
        # This is a no-op when the file is being created or updated through the FileActor.
        # There may be other scenarios where something needs to happen here.
        file_metadata

        # TODO: potentially need to...
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

      private

      ##
      # @return [void]
      # @raise [::Valkyrie::Persistence::StaleObjectError]
      def check_lock_tokens(af_object:, resource:)
        return unless resource.optimistic_locking_enabled?
        return if af_object.new_record?
        return if
          etag_lock_token_valid?(af_object: af_object, resource: resource) &&
          last_modified_lock_token_valid?(af_object: af_object, resource: resource)

        raise(::Valkyrie::Persistence::StaleObjectError, resource.id.to_s)
      end

      ##
      # @return [Boolean]
      def etag_lock_token_valid?(af_object:, resource:)
        etag = resource.optimistic_lock_token.find { |t| t.adapter_id == 'wings-fedora-etag' }

        return true unless etag
        return true if af_object.etag == etag.token

        false
      end

      ##
      # @return [Boolean]
      def last_modified_lock_token_valid?(af_object:, resource:)
        modified = resource.optimistic_lock_token.find { |t| t.adapter_id == 'wings-fedora-last-modified' }

        return true unless modified
        return true if Time.zone.parse(af_object.ldp_source.head.last_modified) <= Time.zone.parse(modified.token)

        false
      end
    end
  end
end
