class BatchCreateJob < ActiveJob::Base
  queue_as :ingest

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  # @param [User] user
  # @param [Hash<String => String>] titles
  # @param [Hash<String => String>] resource_types
  # @param [Array<String>] uploaded_files Sufia::UploadedFile IDs
  # @param [Hash] attributes attributes to apply to all works, including :model
  # @param [BatchCreateOperation] log
  def perform(user, titles, resource_types, uploaded_files, attributes, log)
    log.performing!
    titles ||= {}
    resource_types ||= {}
    create(user, titles, resource_types, uploaded_files, attributes, log)
  end

  private

    def create(user, titles, resource_types, uploaded_files, attributes, log)
      model = attributes.delete(:model) || attributes.delete('model')
      raise ArgumentError, 'attributes must include "model" => ClassName.to_s' unless model
      uploaded_files.each do |upload_id|
        title = [titles[upload_id]] if titles[upload_id]
        resource_type = Array.wrap(resource_types[upload_id]) if resource_types[upload_id]
        attributes = attributes.merge(uploaded_files: [upload_id],
                                      title: title,
                                      resource_type: resource_type)
        child_log = CurationConcerns::Operation.create!(user: user,
                                                        operation_type: "Create Work",
                                                        parent: log)
        CreateWorkJob.perform_later(user, model, attributes, child_log)
      end
    end
end
