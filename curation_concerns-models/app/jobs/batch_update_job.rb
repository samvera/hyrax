class BatchUpdateJob < ActiveJob::Base
  include Hydra::PermissionsQuery
  include CurationConcerns::Messages

  queue_as :batch_update

  attr_accessor :login, :title, :file_attributes, :batch_id, :visibility, :saved, :denied, :work_attributes

  def perform(login, batch_id, title, file_attributes, visibility)
    @login = login
    @title = title || {}
    @file_attributes = file_attributes
    @visibility = visibility
    @work_attributes = file_attributes.merge(visibility: visibility)
    @batch_id = batch_id
    @saved = []
    @denied = []

    batch = Batch.find_or_create(self.batch_id)
    user = User.find_by_user_key(self.login)

    batch.generic_files.each do |gf|
      update_file(gf, user)
    end

    batch.update(status: ["Complete"])

    if denied.empty?
      unless saved.empty?
        if CurationConcerns.config.respond_to?(:after_batch_update_success)
          login = batch.depositor
          user = User.find_by_user_key(login)
          CurationConcerns.config.after_batch_update_failure.call(user, batch, log.created_at)
        end
        return true
      end
    else
      if CurationConcerns.config.respond_to?(:after_batch_update_failure)
        login = batch.depositor
        user = User.find_by_user_key(login)
        CurationConcerns.config.after_batch_update_failure.call(user, batch, log.created_at)
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
    CurationConcerns::GenericFileActor.new(gf, user).update_metadata(file_attributes, visibility: visibility)

    # update the work to the same metadata as the file.
    # NOTE: For the moment we are assuming copied metadata.  This is likely to change.
    # NOTE2: TODO: stop assuming that files only belong to one generic_work
    work = gf.generic_works.first
    unless work.nil?
      work.title = title[gf.id] if title[gf.id]
      CurationConcerns::GenericWorkActor.new(work, user, work_attributes).update
    end

    saved << gf
  end
end
