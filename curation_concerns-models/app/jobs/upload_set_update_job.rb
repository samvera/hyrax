class UploadSetUpdateJob < ActiveJob::Base
  include Hydra::PermissionsQuery
  include CurationConcerns::Messages

  queue_as :upload_set_update

  attr_accessor :saved, :denied

  def perform(login, upload_set_id, titles, attributes, visibility)
    @login = login
    @saved = []
    @denied = []

    titles ||= {}
    attributes = attributes.merge(visibility: visibility)

    upload_set = UploadSet.find_or_create(upload_set_id)

    update(upload_set, titles, attributes)

    if denied.empty?
      unless saved.empty?
        if CurationConcerns.config.callback.set?(:after_upload_set_update_success)
          CurationConcerns.config.callback.run(:after_upload_set_update_success, user, upload_set)
        end
        return true
      end
    else
      if CurationConcerns.config.callback.set?(:after_upload_set_update_failure)
        CurationConcerns.config.callback.run(:after_upload_set_update_failure, user, upload_set)
      end
      return false
    end
  end

  private

    def update(upload_set, titles, attributes)
      upload_set.file_sets.each do |file|
        title = titles[file.id] if titles[file.id]
        next unless update_file(file, title, attributes)
        # TODO: stop assuming that files only belong to one work
        work = file.in_works.first
        update_work(work, title, attributes) if work
        saved << file
      end

      upload_set.update(status: ["Complete"])
    end

    def user
      @user ||= User.find_by_user_key(@login)
    end

    def update_file(file, title, attributes)
      unless user.can? :edit, file
        ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{file.id}!"
        denied << file
        return
      end
      # update the file using the actor after setting the title
      file.title = title if title
      file_actor(file).update_metadata(attributes)
    end

    def file_actor(file)
      CurationConcerns::FileSetActor.new(file, user)
    end

    # update the work to the same metadata as the file.
    # NOTE: For the moment we are assuming copied metadata.  This is likely to change.
    def update_work(work, title, attributes)
      work.title = title if title
      work_actor(work, attributes).update
    end

    def work_actor(work, attributes)
      CurationConcerns::GenericWorkActor.new(work, user, attributes)
    end
end
