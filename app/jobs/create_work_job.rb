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
    if model.constantize < ActiveFedora::Base
      status = batch_create_af_work(work, attributes, user)
      errors = work.errors
    else
      result = batch_create_valkyrie_work(work, attributes, user)
      status = result.success?
      errors = result.failure&.last
    end

    return operation.success! if status
    operation.fail!(errors.full_messages.join(' '))
  end

  private

  def batch_create_af_work(work, attributes, user)
    current_ability = Ability.new(user)
    env = Hyrax::Actors::Environment.new(work, current_ability, attributes)
    work_actor.create(env)
  end

  def batch_create_valkyrie_work(work, attributes, user)
    form_attributes = attributes
    uploaded_file_ids = form_attributes.delete(:uploaded_files)
    files = Hyrax::UploadedFile.find(uploaded_file_ids)
    permissions_params = form_attributes.delete(:permissions_attributes)
    form = Hyrax::FormFactory.new.build(work, nil, nil)
    form.validate(form_attributes)

    transactions['change_set.create_work']
      .with_step_args(
        'work_resource.add_file_sets' => { uploaded_files: files },
        'change_set.set_user_as_depositor' => { user: user },
        'work_resource.change_depositor' => { user: ::User.find_by_user_key(form.on_behalf_of) },
        'work_resource.save_acl' => { permissions_params: permissions_params }
      )
      .call(form)
  end

  def transactions
    Hyrax::Transactions::Container
  end

  def work_actor
    Hyrax::CurationConcern.actor
  end
end
