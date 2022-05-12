# frozen_string_literal: true
require 'active_fedora/cleaner'

module Wings
  module Valkyrie
    ##
    # A valkyrie persister that aims for data consistency/backwards compatibility with ActiveFedora.
    #
    # The guiding principle of design for this persister is that resources persisted with it should
    # be directly readable by `Hydra::Works`-style ActiveFedora models. It aims to be as complete as
    # possible as a Valkyrie Persister, given that limitation.
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
        af_object = resource_factory.from_resource(resource: resource)

        check_lock_tokens(af_object: af_object, resource: resource)

        # the #save! api differs between ActiveFedora::Base and ActiveFedora::File objects,
        # if we get a falsey response, we expect we have a File that has failed to save due
        # to empty content
        af_object.save! ||
          raise(FailedSaveError.new("#{af_object.class}#save! returned non-true. It might be missing required content.", obj: af_object))

        resource_factory.to_resource(object: af_object)
      rescue ActiveFedora::RecordInvalid, RuntimeError => err
        raise MissingOrUnsavedFileError.new(err.message, obj: af_object) if
          err.message == 'Save the file first'

        raise FailedSaveError.new(err.message, obj: af_object)
      end

      # Persists a resource using ActiveFedora
      # @param [Valkyrie::Resource] resource
      # @return [Valkyrie::Resource] the persisted/updated resource
      def save_all(resources:)
        resources.map { |resource| save(resource: resource) }
      rescue ::Valkyrie::Persistence::StaleObjectError => _err
        raise(::Valkyrie::Persistence::StaleObjectError,
              "One or more resources have been updated by another process.")
      end

      # Deletes a resource persisted using ActiveFedora
      # @param [Valkyrie::Resource] resource
      # @return [Valkyrie::Resource] the deleted resource
      def delete(resource:)
        af_object = ActiveFedora::Base.new
        af_object.id = resource.id
        af_object.delete
        resource
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

          msg = "Failed to save object #{obj}.\n" + msg
          super(msg)
        end
      end

      class MissingOrUnsavedFileError < FailedSaveError
        def initialize(msg = nil, obj:)
          msg = "Wings tried to save metadata for a file which has not " \
                "been saved. Fedora creates a metadata node when the file is " \
                "created, so it's not possible to add metadata for a file " \
                "until the file contents are persisted.\n  Use the " \
                "Hyrax.storage_adapter to save the file before trying to " \
                "save metadata.\n" + msg
          super(msg, obj: obj)
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

        raise(::Valkyrie::Persistence::StaleObjectError,
              "The object #{resource.id} has been updated by another process.")
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
