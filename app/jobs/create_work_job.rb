class CreateWorkJob < ActiveJob::Base
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
    actor = work_actor(work, user)
    status = actor.create(attributes)
    return operation.success! if status
    operation.fail!(work.errors.full_messages.join(' '))
  end

  private

    def work_actor(work, user)
      Hyrax::CurationConcern.actor(work, user)
    end
end
