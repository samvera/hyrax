# frozen_string_literal: true
module Hyrax
  class BatchEditsController < ApplicationController
    include FileSetHelper
    include Hyrax::Breadcrumbs
    include Hyrax::Collections::AcceptsBatches

    before_action :build_breadcrumbs, only: :edit
    before_action :filter_docs_with_access!, only: [:edit, :update, :destroy_collection]
    before_action :check_for_empty!, only: [:edit, :update, :destroy_collection]

    # provides the help_text view method
    helper PermissionsHelper

    with_themed_layout 'dashboard'

    def edit
      work = form_class.model_class.new
      work.depositor = current_user.user_key
      @form = form_class.new(work, current_user, batch)
    end

    def after_update
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to_return_controller }
      end
    end

    def after_destroy_collection
      redirect_back fallback_location: hyrax.batch_edits_path
    end

    def check_for_empty!
      return unless check_for_empty_batch?
      redirect_back fallback_location: hyrax.batch_edits_path
      false
    end

    def destroy_collection
      failed_ids = batch.reject { |id| destroy_resource(id) }.map(&:to_s)
      return after_destroy_collection_failure(failed_ids) if failed_ids.any?

      flash[:notice] = "Batch delete complete"
      after_destroy_collection
    end

    def update_document(obj)
      interpret_visiblity_params(obj)
      obj.attributes = work_params(admin_set_id: obj.admin_set_id).except(*visibility_params)
      obj.date_modified = TimeService.time_in_utc

      InheritPermissionsJob.perform_now(obj)
      VisibilityCopyJob.perform_now(obj)

      obj.save
    end

    def valkyrie_update_document(obj)
      form = form_class.new(obj, current_ability, nil)
      return unless form.validate(params[form_class.model_class.model_name.param_key])

      cleanup_form_fields form

      result = transactions['change_set.update_work']
               .with_step_args('work_resource.save_acl' => { permissions_params: form.input_params["permissions"] })
               .call(form)
      obj = result.value!

      InheritPermissionsJob.perform_now(obj)
      VisibilityCopyJob.perform_now(obj)
    end

    def update
      case params["update_type"]
      when "update"
        batch.each do |doc_id|
          if Hyrax.config.use_valkyrie?
            valkyrie_update_document(Hyrax.query_service.find_by(id: doc_id))
          else
            update_document(Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: doc_id, use_valkyrie: false))
          end
        end
        flash[:notice] = "Batch update complete"
        after_update
      when "delete_all"
        destroy_batch
      end
    end

    private

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
    end

    def _prefixes
      # This allows us to use the templates in hyrax/base, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      @_prefixes ||= super + ['hyrax/base']
    end

    def destroy_batch
      batch.each do |id|
        resource = Hyrax.query_service.find_by(id: Valkyrie::ID.new(id))
        transactions['work_resource.destroy']
          .with_step_args('work_resource.delete' => { user: current_user },
                          'work_resource.delete_all_file_sets' => { user: current_user })
          .call(resource).value!
      end
      after_update
    end

    def destroy_resource(id)
      resource = Hyrax.query_service.find_by(id: Valkyrie::ID.new(id))
      result = destroy_transaction_for(resource).call(resource)
      Hyrax.logger.error("Batch delete failed for #{id}: #{Array(result.failure).first.inspect}") if result.failure?
      result.success?
    rescue StandardError => e
      Hyrax.logger.error("Batch delete failed for #{id}: #{e.class}: #{e.message}")
      false
    end

    def after_destroy_collection_failure(failed_ids)
      respond_to do |format|
        format.json { render json: { failed_ids: failed_ids }, status: :unprocessable_entity }
        format.html do
          flash[:alert] = t('hyrax.batch_edits.destroy_collection.failed', count: failed_ids.count)
          after_destroy_collection
        end
      end
    end

    DESTROY_STEPS_NEEDING_USER = {
      'admin_set_resource.destroy' => [],
      'collection_resource.destroy' => ['collection_resource.delete', 'collection_resource.remove_from_membership'],
      'file_set.destroy' => ['file_set.remove_from_work', 'file_set.delete'],
      'work_resource.destroy' => ['work_resource.delete', 'work_resource.delete_all_file_sets']
    }.freeze

    def destroy_transaction_for(resource)
      name = destroy_transaction_name(resource)
      transactions[name].with_step_args(**DESTROY_STEPS_NEEDING_USER[name].index_with { { user: current_user } })
    end

    # Admin sets also answer true to #collection?, so they are matched first.
    def destroy_transaction_name(resource)
      if Hyrax::ModelRegistry.admin_set_classes.any? { |klass| resource.is_a?(klass) }
        'admin_set_resource.destroy'
      elsif resource.try(:collection?)
        'collection_resource.destroy'
      elsif resource.try(:file_set?)
        'file_set.destroy'
      elsif resource.try(:work?)
        'work_resource.destroy'
      else
        raise ArgumentError, "#{resource.class} cannot be bulk deleted"
      end
    end

    def form_class
      Hyrax.config.use_valkyrie? ? Forms::ResourceBatchEditForm : Forms::BatchEditForm
    end

    def terms
      form_class.terms
    end

    def work_params(extra_params = {})
      work_params = params[form_class.model_class.model_name.param_key] || ActionController::Parameters.new
      form_class.model_attributes(work_params.merge(extra_params))
    end

    def interpret_visiblity_params(obj)
      stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
        middleware.use Hyrax::Actors::InterpretVisibilityActor
      end
      env = Hyrax::Actors::Environment.new(obj, current_ability, work_params(admin_set_id: obj.admin_set_id))
      last_actor = Hyrax::Actors::Terminator.new
      stack.build(last_actor).update(env)
    end

    def visibility_params
      ['visibility',
       'lease_expiration_date',
       'visibility_during_lease',
       'visibility_after_lease',
       'embargo_release_date',
       'visibility_during_embargo',
       'visibility_after_embargo']
    end

    def redirect_to_return_controller
      if params[:return_controller]
        redirect_to hyrax.url_for(controller: params[:return_controller], only_path: true)
      else
        redirect_to hyrax.dashboard_path
      end
    end

    # Clean up form fields
    # @param form Hyrax::Froms::ResourceBatchEditForm
    def cleanup_form_fields(form)
      form.lease = nil if form.lease && form.lease.fields['lease_expiration_date'].nil?
      form.embargo = nil if form.embargo && form.embargo.fields['embargo_release_date'].nil?
      form.fields.keys.each do |k|
        form.fields[k] = nil if form.fields[k].is_a?(Array) && form.fields[k].blank?
      end
    end
  end
end
