# frozen_string_literal: true

require 'hooks'

module Hyrax
  # ChangeSetPersisters are used to apply ChangeSets (updates) to resources,
  # formerly known as curation_concerns, in Hyrax.  A ChangeSetPersister initalizes
  # with adapters for persisting the metadata and storing the resource.  It should
  # then be called for the desired operation (save, delete, etc) with the ChangeSet
  # that contains the resource and changes you wish to make
  #
  # @since 3.0.0
  class ChangeSetPersister
    include Hooks
    define_hooks :before_save, :after_save, :before_delete, :after_delete

    after_save :append_to_parent

    attr_reader :metadata_adapter, :storage_adapter
    delegate :persister, :query_service, to: :metadata_adapter

    # Initalizes the ChangeSetPersister
    # @param [Valkyrie::MetadataAdapter] metadata_adapter The adapter you wish to
    #   apply the changes to the resource in
    # @param [Valkyrie::StorageAdapter] the storage_adapter you wish to store the
    #   changes to the resource in
    def initialize(metadata_adapter:, storage_adapter:)
      @metadata_adapter = metadata_adapter
      @storage_adapter = storage_adapter
    end

    # Saves all changes in the ChangeSet to the resource contained in the ChangeSet
    # using the metadata_adapter and storage_adapter
    # @param [Hyrax::ChangeSet] change_set The change_set whose resource you wish to save
    # @return the saved resource, such as GenericWork, that is subclassed from Valkyrie::Resource
    def save(change_set:)
      run_hook(:before_save, change_set: change_set)
      resource = persister.save(resource: change_set.resource)
      run_hook(:after_save, change_set: change_set, resource: resource)
      query_service.find_by(id: resource.id)
    end

    # Deletes the resource contained in the change_set from the adapters specified
    # upon initialization of the ChangeSetPersister
    # @param [Hyrax::ChangeSet] change_set The change_set whose resource you wish to delete
    def delete(change_set:)
      run_hook(:before_delete, change_set: change_set)
      persister.delete(resource: change_set.resource)
      run_hook(:after_delete, change_set: change_set)
    end

    # Calls save on all change_sets in the array passed in
    # @param [Array <Hyrax::ChangeSet>] change_sets An array of change_sets whose resources you wish to save
    # @return [Array <Valkyrie::Resource>] an array of the saved resources, such as GenericWork,
    #   subclassed from Valkyrie::Resource
    def save_all(change_sets:)
      change_sets.map do |change_set|
        save(change_set: change_set)
      end
    end

    # Calls delete on all change_sets in the arraypassed in
    # @param [Array <Hyrax::ChangeSet>] change_sets An array of change_sets whose resources you wish to delete
    #  all resources were succesfully deleted
    def delete_all(change_sets:)
      change_sets.map do |change_set|
        delete(change_set: change_set)
      end
    end

    def buffer_into_index
      metadata_adapter.persister.buffer_into_index do |buffered_adapter|
        with(metadata_adapter: buffered_adapter) do |buffered_changeset_persister|
          yield(buffered_changeset_persister)
        end
      end
    end

    def with(metadata_adapter:)
      yield self.class.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter)
    end

    before_delete do |params|
      parents = query_service.find_inverse_references_by(resource: params[:change_set].resource, property: :member_ids)
      parents.each do |parent|
        parent.member_ids.delete(params[:change_set].resource.id)
        persister.save(resource: parent)
      end
    end

    private

      def append_to_parent(change_set:, resource:)
        return unless change_set.append_id

        parent_obj = query_service.find_by(id: change_set.append_id)
        parent_obj.member_ids = parent_obj.member_ids + [resource.id]
        persister.save(resource: parent_obj)
      end
  end
end
