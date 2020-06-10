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
    current_ability = Ability.new(user)
    env = Hyrax::Actors::Environment.new(work, current_ability, attributes)
    status = work_actor.create(env)
    return operation.success! if status
    operation.fail!(work.errors.full_messages.join(' '))
  end

  private

  def work_actor
    Hyrax::CurationConcern.actor
  end
end
