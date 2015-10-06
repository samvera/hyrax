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

    upload_set.file_sets.each do |gf|
      update_file(gf, user)
    end

    upload_set.update(status: ["Complete"])

    if denied.empty?
      unless saved.empty?
        if CurationConcerns.config.respond_to?(:after_upload_set_update_success)
          login = upload_set.depositor
          user = User.find_by_user_key(login)
          CurationConcerns.config.after_upload_set_update_failure.call(user, upload_set, log.created_at)
        end
        return true
      end
    else
      if CurationConcerns.config.respond_to?(:after_upload_set_update_failure)
        login = upload_set.depositor
        user = User.find_by_user_key(login)
        CurationConcerns.config.after_upload_set_update_failure.call(user, upload_set, log.created_at)
      end
      return false
    end
  end

  def update_file(gf, user)
    unless user.can? :edit, gf
      ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{gf.id}!"
      denied << gf
      return
    end
    # update the file using the actor after setting the title
    gf.title = title[gf.id] if title[gf.id]
    CurationConcerns::FileSetActor.new(gf, user).update_metadata(file_attributes, visibility: visibility)

    # update the work to the same metadata as the file.
    # NOTE: For the moment we are assuming copied metadata.  This is likely to change.
    # NOTE2: TODO: stop assuming that files only belong to one work
    work = gf.in_works.first
    unless work.nil?
      work.title = title[gf.id] if title[gf.id]
      CurationConcerns::GenericWorkActor.new(work, user, work_attributes).update
    end

    saved << gf
  end
end
