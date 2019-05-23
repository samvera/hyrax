# frozen_string_literal: true
require 'wings/models/file_node'

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
        return save_file(file_node: resource) if resource.is_a? Wings::FileNode

        # Update the lock for atomic updates
        # Should the lock in the object state be one in the same for this timestamp,
        # then a race condition has occurred
        # The downside is that we don't permit a series of updates which happen
        # within the range of the Time.new.to_r accuracy
        if resource.attributes.key?(::Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK)
          raise ::Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." unless valid_lock?(resource)
          resource.optimistic_lock_token = generate_lock_token
        end

        af_object = resource_factory.from_resource(resource: resource)
        af_object.save!
        resource_factory.to_resource(object: af_object)
      rescue ActiveFedora::RecordInvalid => err
        raise FailedSaveError.new(err.message, obj: af_object)
      end

      def save_file(file_node:)
        # TODO: SKIP for now
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
        ActiveFedora::SolrService.instance.conn.delete_by_query("*:*")
        ActiveFedora::SolrService.instance.conn.commit
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

        # Access the Valkyrie query service from the metadata persister
        # @return [Wings::Valkyrie::QueryService]
        def query_service
          adapter.query_service
        end

        # Determines whether or not the resource being saved has a valid lock
        # for persisted
        # @param resource [Valkyrie::Resource]
        # @return [Boolean]
        def valid_lock?(resource)
          return true unless resource.optimistic_locking_enabled?
          return true if resource.id.nil?

          current_lock_tokens = resource[::Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
          current_lock_tokens = Array.wrap(current_lock_tokens)
          current_lock_token = current_lock_tokens.first
          return true if current_lock_token.nil?

          # Retrieve any existing lock tokens from the query service
          persisted = query_service.find_by(id: resource.id)
          retrieved_lock_tokens = persisted[::Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]

          return true if retrieved_lock_tokens.empty?
          retrieved_lock_token = retrieved_lock_tokens.first

          retrieved_lock = ::Valkyrie::Persistence::OptimisticLockToken.deserialize(retrieved_lock_token)
          current_lock = ::Valkyrie::Persistence::OptimisticLockToken.deserialize(current_lock_token)
          # For cases such as migrations, optimistic locking is not supported when
          # two separate persistence adapters modify the same resource
          return true if current_lock.adapter_id != retrieved_lock.adapter_id

          # This logic is usually row-specific for ActiveRecord
          # @see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/locking/optimistic.rb#L95
          # For Valkyrie resources, the last atomic update to the underlying data
          # store should leave the token in the same
          current_lock == retrieved_lock
        end

        # Generates a new optimistic lock token
        # @see Valkyrie::Persistence::Fedora::Persister#generate_lock_token(resource)
        # @return [OptimisticLockToken]
        def generate_lock_token
          ::Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: adapter.id, token: Time.current.to_r)
        end
    end
  end
end
