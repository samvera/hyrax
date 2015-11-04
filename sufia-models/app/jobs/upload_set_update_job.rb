class UploadSetUpdateJob
  include Hydra::PermissionsQuery
  include CurationConcerns::Messages

  def queue_name
    :batch_update
  end

  attr_accessor :login, :title, :file_attributes, :upload_set_id, :visibility, :saved, :denied, :work_attributes

  def initialize(login, upload_set_id, title, file_attributes, visibility)
    self.login = login
    self.title = title || {}
    self.file_attributes = file_attributes
    self.visibility = visibility
    self.work_attributes = file_attributes.merge(visibility: visibility)
    self.upload_set_id = upload_set_id
    self.saved = []
    self.denied = []
  end

  def run
    batch = UploadSet.find_or_create(upload_set_id)
    user = User.find_by_user_key(login)

    batch.file_sets.each do |fs|
      update_file(fs, user)
    end

    batch.update(status: ["Complete"])

    if denied.empty?
      send_user_success_message(user, batch) unless saved.empty?
    else
      send_user_failure_message(user, batch)
    end
  end

  def update_file(fs, user)
    unless user.can? :edit, fs
      ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{fs.id}!"
      denied << fs
      return
    end
    # update the file using the actor after setting the title
    fs.title = title[fs.id] if title[fs.id]
    CurationConcerns::FileSetActor.new(fs, user).update_metadata(file_attributes, visibility: visibility)

    # update the work to the same metadata as the file.
    # NOTE: For the moment we are assuming copied metadata.  This is likely to change.
    # NOTE2: TODO: stop assuming that files only belong to one generic_work
    work = fs.generic_works.first
    unless work.nil?
      work.title = title[fs.id] if title[fs.id]
      CurationConcerns::GenericWorkActor.new(work, user, work_attributes).update
    end

    saved << fs
  end

  def send_user_success_message(user, batch)
    message = saved.count > 1 ? multiple_success(batch.id, saved) : single_success(batch.id, saved.first)
    User.batchuser.send_message(user, message, success_subject, false)
  end

  def send_user_failure_message(user, batch)
    message = denied.count > 1 ? multiple_failure(batch.id, denied) : single_failure(batch.id, denied.first)
    User.batchuser.send_message(user, message, failure_subject, false)
  end
end
