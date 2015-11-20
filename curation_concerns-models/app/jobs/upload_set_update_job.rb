class UploadSetUpdateJob < ActiveJob::Base
  include Hydra::PermissionsQuery
  include CurationConcerns::Messages

  queue_as :upload_set_update

  attr_accessor :login, :title, :file_attributes, :upload_set_id, :visibility, :saved, :denied, :work_attributes

  def perform(login, upload_set_id, title, file_attributes, visibility)
    @login = login
    @title = title || {}
    @file_attributes = file_attributes
    @visibility = visibility
    @work_attributes = file_attributes.merge(visibility: visibility)
    @upload_set_id = upload_set_id
    @saved = []
    @denied = []

    upload_set = UploadSet.find_or_create(self.upload_set_id)
    user = User.find_by_user_key(self.login)

    upload_set.file_sets.each do |file|
      update_file(file, user)
    end

    upload_set.update(status: ["Complete"])

    if denied.empty?
      unless saved.empty?
        if CurationConcerns.config.callback.set?(:after_upload_set_update_success)
          user = User.find_by_user_key(@login)
          CurationConcerns.config.callback.run(:after_upload_set_update_success, user, upload_set, log.created_at)
        end
        return true
      end
    else
      if CurationConcerns.config.callback.set?(:after_upload_set_update_failure)
        user = User.find_by_user_key(@login)
        CurationConcerns.config.callback.run(:after_upload_set_update_failure. user, upload_set, log.created_at)
      end
      return false
    end
  end

  def update_file(file, user)
    unless user.can? :edit, file
      ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{file.id}!"
      denied << file
      return
    end
    # update the file using the actor after setting the title
    file.title = title[file.id] if title[file.id]
    CurationConcerns::FileSetActor.new(file, user).update_metadata(file_attributes.merge(visibility: visibility))

    # update the work to the same metadata as the file.
    # NOTE: For the moment we are assuming copied metadata.  This is likely to change.
    # NOTE2: TODO: stop assuming that files only belong to one work
    work = file.in_works.first
    unless work.nil?
      work.title = title[file.id] if title[file.id]
      CurationConcerns::GenericWorkActor.new(work, user, work_attributes).update
    end

    saved << file
  end
end
