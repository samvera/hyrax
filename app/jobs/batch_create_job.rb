# frozen_string_literal: true
class BatchCreateJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  before_enqueue do |job|
    operation = job.arguments.last
    operation.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  # @param [User] user
  # @param [Hash<String => String>] titles
  # @param [Hash<String => String>] resource_types
  # @param [Array<String>] uploaded_files Hyrax::UploadedFile IDs
  # @param [Hash] attributes attributes to apply to all works, including :model
  # @param [Hyrax::BatchCreateOperation] operation
  def perform(user, titles, resource_types, uploaded_files, attributes, operation)
    operation.performing!
    titles ||= {}
    resource_types ||= {}
    create(user, titles, resource_types, uploaded_files, attributes, operation)
  end

  private

  def create(user, titles, resource_types, uploaded_files, attributes, operation)
    job_attributes = attributes
    model = job_attributes.delete(:model) || job_attributes.delete('model')
    raise ArgumentError, 'attributes must include "model" => ClassName.to_s' unless model
    uploaded_files.each do |upload_id|
      title = [titles[upload_id]] if titles[upload_id]
      resource_type = Array.wrap(resource_types[upload_id]) if resource_types[upload_id]
      job_attributes = job_attributes.merge(uploaded_files: [upload_id],
                                            title: title,
                                            resource_type: resource_type)
      child_operation = Hyrax::Operation.create!(user: user,
                                                 operation_type: "Create Work",
                                                 parent: operation)
      CreateWorkJob.perform_later(user, model, job_attributes, child_operation)
    end
  end
end
