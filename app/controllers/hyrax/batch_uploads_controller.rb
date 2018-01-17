module Hyrax
  class BatchUploadsController < ApplicationController
    include Hydra::Controller::ControllerBehavior
    include Hyrax::WorksControllerBehavior

    # We use BatchUploadItem as a null stand-in resource_type.
    self.resource_class = BatchUploadItem
    self.change_set_class = BatchUploadChangeSet

    with_themed_layout 'dashboard'

    # The permissions to create a batch are not as important as the permissions for the concern being batched.
    # @note we don't call `authorize!` directly, since `authorized_models` already checks `user.can? :create, ...`
    def create
      authenticate_user!
      if Flipflop.batch_upload?
        handle_payload_concern!
        redirect_after_update!
      else
        respond_with_batch_upload_disabled
      end
    end

    private

      def respond_with_batch_upload_disabled
        respond_to do |wants|
          wants.json do
            return render_json_response(response_type: :forbidden, message: view_context.t('hyrax.batch_uploads.disabled'))
          end
          wants.html do
            return redirect_to hyrax.my_works_path, alert: view_context.t('hyrax.batch_uploads.disabled')
          end
        end
      end

      def build_change_set(resource)
        super.tap do |change_set|
          change_set.payload_concern = params[:payload_concern]
        end
      end

      def handle_payload_concern!
        unsafe_pc = resource_params.delete(:payload_concern)
        # Calling constantize on user params is disfavored (per brakeman), so we sanitize by matching it against an authorized model.
        safe_pc = Hyrax::SelectTypeListPresenter.new(current_user).authorized_models.map(&:to_s).find { |x| x == unsafe_pc }
        raise CanCan::AccessDenied, "Cannot create an object of class '#{unsafe_pc}'" unless safe_pc
        # authorize! :create, safe_pc
        create_job(safe_pc)
      end

      def redirect_after_update!
        # Calling `#t` in a controller context does not mark _html keys as html_safe
        flash[:notice] = view_context.t('hyrax.works.create.after_create_html', application_name: view_context.application_name)
        if uploading_on_behalf_of?
          redirect_to hyrax.dashboard_shares_path
        else
          redirect_to hyrax.my_works_path
        end
      end

      # @param [String] klass the name of the Hyrax Work Class being created by the batch
      # @note Cannot use a proper Class here because it won't serialize
      def create_job(klass)
        operation = BatchCreateOperation.create!(user: current_user,
                                                 operation_type: "Batch Create")
        # ActionController::Parameters are not serializable, so cast to a hash
        BatchCreateJob.perform_later(current_user,
                                     params[:title].permit!.to_h,
                                     params.fetch(:resource_type, {}).permit!.to_h,
                                     params[:uploaded_files],
                                     create_attributes(klass),
                                     operation)
      end

      def uploading_on_behalf_of?
        resource_params.key?(:on_behalf_of)
      end

      def resource_params
        @resource_params ||= params[resource_class.model_name.param_key] || {}
      end

      # Strip out any blank spaces and add the model.
      # @example:
      #   params[:title]
      #   # => { title: [''] }
      #   create_attributes(GenericWork)
      #   # => { title: [], model: GenericWork }
      def create_attributes(klass)
        resource_params
          .to_unsafe_h
          .each_value { |v| v.delete('') }
          .merge(model: klass)
      end
  end
end
