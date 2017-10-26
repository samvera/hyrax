# This is a job spawned by the BatchCreateJob
class CreateWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  before_enqueue do |job|
    operation = job.arguments.last
    operation.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  # @param [User] user
  # @param [String] model
  # @param [Hash] attributes
  # @param [Hyrax::BatchCreateOperation] operation
  def perform(user, model, attributes, operation)
    operation.performing!
    work = model.constantize.new
    change_set = Hyrax::DynamicChangeSet.new(work, ability: Ability.new(user))
    status = change_set.validate(attributes)
    return operation.fail!(change_set.errors.full_messages.join(' ')) unless status
    change_set.sync
    change_set_persister.buffer_into_index do |persist|
      persist.save(change_set: change_set)
    end
    operation.success!
  end

  private

    def change_set_persister
      Hyrax::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
