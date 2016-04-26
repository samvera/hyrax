class BatchCreateJob < ActiveJob::Base
  queue_as :batch_create

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  def perform(user, titles, resource_types, uploaded_files, attributes, log)
    log.performing!

    titles ||= {}
    resource_types ||= {}

    create(user, titles, resource_types, uploaded_files, attributes, log)
  end

  private

    def create(user, titles, resource_types, uploaded_files, attributes, log)
      uploaded_files.each do |upload_id|
        title = [titles[upload_id]] if titles[upload_id]
        resource_type = [resource_types[upload_id]] if resource_types[upload_id]
        attributes = attributes.merge(uploaded_files: [upload_id], title: title, resource_type: resource_type)
        child_log = CurationConcerns::Operation.create!(user: user,
                                                        operation_type: "Create Work",
                                                        parent: log)
        CreateWorkJob.perform_later(user, attributes, child_log)
      end
    end
end
