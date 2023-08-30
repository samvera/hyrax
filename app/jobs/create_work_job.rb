# frozen_string_literal: true
# This is a job spawned by the BatchCreateJob
class CreateWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  before_enqueue do |job|
    operation = job.arguments.last
    operation.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  # @param [User] user
  # @param [String] model
  # @param [Hash] attributes
  # @param [Hyrax::BatchCreateOperation] operation
  def perform(user, model, attributes, operation)
    operation.performing!
    work = model.constantize.new
    current_ability = Ability.new(user)
    env = Hyrax::Actors::Environment.new(work, current_ability, attributes)
    status = if model == ActiveFedora::Base
               work_actor.create(env)
             else
               batch_create_valkyrie_work(work, attributes, user)
             end
    return operation.success! if status
    operation.fail!(work.errors.full_messages.join(' '))
  end

  private

  def work_actor
    Hyrax::CurationConcern.actor
  end

  def batch_create_valkyrie_work(work, attributes, user)
    uploaded_file_ids = attributes.delete(:uploaded_files)
    files = Hyrax::UploadedFile.find(uploaded_file_ids)
    work.title = attributes.delete(:title)
    work.resource_type = attributes.delete(:resource_type)
    work.visibility = attributes.delete(:visibility)
    work.depositor = user.user_key
    work.creator = attributes.delete(:creator)
    work.rights_statement = [attributes.delete(:rights_statement)]
    permissions = work.permission_manager.acl.permissions
    generic_work = Hyrax.persister.save(resource: work)
    generic_work.permission_manager.acl.permissions = permissions
    generic_work.permission_manager.acl.save
    Hyrax::WorkUploadsHandler.new(work: generic_work).add(files: files).attach
  end
end
