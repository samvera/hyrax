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
    change_set = change_set_class(model).new(work, attributes)
    status = work_actor.create(actor_env(change_set, user, attributes))
    return operation.success! if status
    operation.fail!(change_set.errors.full_messages.join(' '))
  end

  private

    def actor_env(change_set, user, attributes)
      Hyrax::Actors::Environment.new(change_set,
                                     persister,
                                     current_ability(user),
                                     attributes)
    end

    def current_ability(user)
      Ability.new(user)
    end

    def persister
      Hyrax::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    def change_set_class(model)
      "#{model}ChangeSet".constantize
    end

    def work_actor
      Hyrax::CurationConcern.actor
    end
end
