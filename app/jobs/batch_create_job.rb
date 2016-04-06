class BatchCreateJob < ActiveJob::Base
  include Hydra::PermissionsQuery
  include CurationConcerns::Messages

  queue_as :batch_create

  attr_accessor :saved, :success

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  def perform(user, titles, uploaded_files, attributes)
    @saved = []
    @success = true

    titles ||= {}

    create(user, titles, uploaded_files, attributes)
    send_user_message(user)
  end

  private

    def create(user, titles, uploaded_files, attributes)
      uploaded_files.each do |upload_id|
        title = titles[upload_id] if titles[upload_id]
        work = create_work(user,
                           attributes.merge(uploaded_files: [upload_id],
                                            title: title))
        # TODO: stop assuming that files only belong to one work
        next unless work
        saved << work
      end
    end

    def send_user_success_message(user)
      return unless CurationConcerns.config.callback.set?(:after_upload_set_update_success)
      CurationConcerns.config.callback.run(:after_upload_set_update_success, user)
    end

    def send_user_failure_message(user)
      return unless CurationConcerns.config.callback.set?(:after_upload_set_update_failure)
      CurationConcerns.config.callback.run(:after_upload_set_update_failure, user)
    end

    def send_user_message(user)
      if success
        send_user_success_message(user) unless saved.empty?
      else
        send_user_failure_message(user)
      end
    end

    def create_work(user, attributes)
      actor = work_actor(GenericWork.new, user)
      result = actor.create(attributes)
      Rails.logger.error "There was a problem with batch create: #{actor.curation_concern.errors.full_messages}" unless result
      @success &&= result
    end

    def work_actor(work, user)
      # TODO: merge this with the actor method from works_controller.
      CurationConcerns::CurationConcern::ActorStack.new(
        work,
        user,
        [Sufia::CreateWithFilesActor,
         CurationConcerns::AddToCollectionActor,
         CurationConcerns::AssignRepresentativeActor,
         CurationConcerns::AttachFilesActor,
         CurationConcerns::ApplyOrderActor,
         CurationConcerns::InterpretVisibilityActor,
         CurationConcerns::CurationConcern.model_actor(work),
         CurationConcerns::AssignIdentifierActor])
    end
end
