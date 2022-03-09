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
      batch.each do |doc_id|
        resource = Hyrax.query_service.find_by(id: Valkyrie::ID.new(doc_id))
        transactions['collection_resource.destroy']
          .with_step_args('collection_resource.delete' => { user: current_user })
          .call(resource)
          .value!
      end
      flash[:notice] = "Batch delete complete"
      after_destroy_collection
    end

    def update_document(obj)
      interpret_visiblity_params(obj)
      obj.attributes = work_params(admin_set_id: obj.admin_set_id).except(*visibility_params)
      obj.date_modified = Time.current.ctime

      InheritPermissionsJob.perform_now(obj, use_valkyrie: false)
      VisibilityCopyJob.perform_now(obj)

      obj.save
    end

    def update
      case params["update_type"]
      when "update"
        batch.each do |doc_id|
          update_document(Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: doc_id, use_valkyrie: false))
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
          .with_step_args('work_resource.delete' => { user: current_user })
          .call(resource)
          .value!
      end
      after_update
    end

    def form_class
      Forms::BatchEditForm
    end

    def terms
      form_class.terms
    end

    def work_params(extra_params = {})
      work_params = params[form_class.model_name.param_key] || ActionController::Parameters.new
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
  end
end
