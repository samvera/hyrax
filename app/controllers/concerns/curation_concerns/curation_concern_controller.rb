module CurationConcerns
  module CurationConcernController
    extend ActiveSupport::Concern
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog

    included do
      copy_blacklight_config_from(::CatalogController)
      include CurationConcerns::ThemedLayoutController
      with_themed_layout '1_column'
      helper CurationConcerns::AbilityHelper

      class_attribute :_curation_concern_type, :show_presenter, :work_form_service
      self.show_presenter = WorkShowPresenter
      self.work_form_service = WorkFormService
      attr_accessor :curation_concern
      helper_method :curation_concern, :contextual_path

      rescue_from WorkflowAuthorizationException, with: :render_unavailable
    end

    module ClassMethods
      def curation_concern_type=(curation_concern_type)
        load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern, except: [:show, :file_manager, :inspect_work]
        self._curation_concern_type = curation_concern_type
      end

      def curation_concern_type
        _curation_concern_type
      end

      def cancan_resource_class
        CurationConcerns::ControllerResource
      end
    end

    def new
      build_form
    end

    def create
      if actor.create(attributes_for_actor)
        after_create_response
      else
        respond_to do |wants|
          wants.html do
            build_form
            render 'new', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end
    end

    # Finds a solr document matching the id and sets @presenter
    # @raises CanCan::AccessDenied if the document is not found
    #   or the user doesn't have access to it.
    def show
      respond_to do |wants|
        wants.html { presenter && parent_presenter }
        wants.json do
          # load and authorize @curation_concern manually because it's skipped for html
          @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern
          authorize! :show, @curation_concern
          render :show, status: :ok
        end
        additional_response_formats(wants)
        wants.ttl do
          render body: presenter.export_as_ttl, content_type: 'text/turtle'
        end
        wants.jsonld do
          render body: presenter.export_as_jsonld, content_type: 'application/ld+json'
        end
        wants.nt do
          render body: presenter.export_as_nt, content_type: 'application/n-triples'
        end
      end
    end

    def edit
      build_form
    end

    def update
      if actor.update(attributes_for_actor)
        after_update_response
      else
        respond_to do |wants|
          wants.html do
            build_form
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end
    end

    def destroy
      title = curation_concern.to_s
      if actor.destroy
        CurationConcerns.config.callback.run(:after_destroy, curation_concern.id, current_user)
        after_destroy_response(title)
      end
    end

    def file_manager
      presenter
    end

    def inspect_work
      raise Hydra::AccessDenied unless current_ability.admin?
      presenter
    end

    attr_writer :actor

    protected

      def build_form
        @form = work_form_service.build(curation_concern, current_ability)
      end

      def actor
        @actor ||= CurationConcerns::CurationConcern.actor(curation_concern, current_user)
      end

      def presenter
        @presenter ||= show_presenter.new(curation_concern_from_search_results, current_ability, request)
      end

      def parent_presenter
        @parent_presenter ||=
          begin
            if params[:parent_id]
              @parent_presenter ||= show_presenter.new(search_result_document(id: params[:parent_id]), current_ability, request)
            end
          end
      end

      # Include 'curation_concerns/base' in the search path for views, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['curation_concerns/base']
      end

      def after_create_response
        respond_to do |wants|
          wants.html { redirect_to contextual_path(curation_concern, parent_presenter) }
          wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
        end
      end

      def after_update_response
        # TODO: visibility or lease/embargo status
        if curation_concern.visibility_changed? && curation_concern.file_sets.present?
          redirect_to main_app.confirm_curation_concerns_permission_path(curation_concern)
        else
          respond_to do |wants|
            wants.html { redirect_to [main_app, curation_concern] }
            wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
          end
        end
      end

      def after_destroy_response(title)
        flash[:notice] = "Deleted #{title}"
        respond_to do |wants|
          wants.html { redirect_to main_app.search_catalog_path }
          wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
        end
      end

      def attributes_for_actor
        raw_params = params[hash_key_for_curation_concern]
        return unless raw_params
        work_form_service.form_class(curation_concern).model_attributes(raw_params)
      end

      def hash_key_for_curation_concern
        _curation_concern_type.model_name.param_key
      end

      # Override this method to add additional response
      # formats to your local app
      def additional_response_formats(_)
        # nop
      end

      def search_builder_class
        CurationConcerns::WorkSearchBuilder
      end

      def contextual_path(presenter, parent_presenter)
        ::CurationConcerns::ContextualPath.new(presenter, parent_presenter).show
      end

    private

      def curation_concern_from_search_results
        search_result_document(params)
      end

      # Only returns unsuppressed documents the user has read access to
      def search_result_document(search_params)
        _, document_list = search_results(search_params)
        return document_list.first unless document_list.empty?
        document_not_found!
      end

      def document_not_found!
        doc = SolrDocument.find(params[:id])
        raise WorkflowAuthorizationException if doc.suppressed?
        raise CanCan::AccessDenied.new(nil, :show)
      end

      def render_unavailable
        message = I18n.t("curation_concerns.workflow.unauthorized")
        respond_to do |wants|
          wants.html do
            flash[:notice] = message
            render 'unavailable', status: :unauthorized
          end
          wants.json do
            render plain: message, status: :unauthorized
          end
          additional_response_formats(wants)
          wants.ttl do
            render plain: message, status: :unauthorized
          end
          wants.jsonld do
            render plain: message, status: :unauthorized
          end
          wants.nt do
            render plain: message, status: :unauthorized
          end
        end
      end
  end
end
