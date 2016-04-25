class CreateWorkJob < ActiveJob::Base
  queue_as :create_work

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  def perform(user, attributes, log)
    log.performing!

    work = GenericWork.new
    actor = work_actor(work, user)
    status = actor.create(attributes)
    return log.success! if status
    log.fail!(work.errors.full_messages.join(' '))
  end

  private

    def work_actor(work, user)
      CurationConcerns::CurationConcern.actor(work, user)
    end
end
