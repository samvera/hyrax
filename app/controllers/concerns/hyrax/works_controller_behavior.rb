module Hyrax
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include ResourceController

    included do
      layout :decide_layout

      copy_blacklight_config_from(::CatalogController)
      class_attribute :show_presenter, :search_builder_class
      self.show_presenter = Hyrax::WorkShowPresenter
      self.search_builder_class = WorkSearchBuilder
      self.change_set_persister = Hyrax::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )

      attr_accessor :curation_concern
      helper_method :curation_concern, :contextual_path

      rescue_from WorkflowAuthorizationException, with: :render_unavailable
    end

    def create
      @change_set = change_set_class.new(resource_class.new)
      authorize! :create, @change_set.resource
      if actor.create(actor_environment)
        after_create_success(@resource, @change_set)
      else
        after_create_error(@resource, @change_set)
      end
    end

    def update
      @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :update, @change_set.resource
      if actor.update(actor_environment)
        after_update_success(@change_set.resource, @change_set)
      else
        after_update_error(@change_set.resource, @change_set)
      end
    end

    def destroy
      @change_set = change_set_class.new(find_resource(params[:id]))
      authorize! :destroy, @change_set.resource
      env = Actors::Environment.new(@change_set.resource, current_ability, {})
      return unless actor.destroy(env)
      after_delete_success(@change_set)
    end

    # Finds a solr document matching the id and sets @presenter
    # @raise CanCan::AccessDenied if the document is not found or the user doesn't have access to it.
    def show
      respond_to do |wants|
        wants.html { presenter && parent_presenter }
        wants.json do
          # load and authorize @curation_concern manually because it's skipped for html
          @curation_concern = Hyrax::Queries.find_by(id: Valkyrie::ID.new(params[:id])) unless curation_concern
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

    def inspect_work
      raise Hydra::AccessDenied unless current_ability.admin?
      presenter
    end

    private

      # Overridden to provide depositor (used on app/views/hyrax/base/_form_share.html.erb)
      def build_change_set(resource)
        change_set_class.new(resource,
                             depositor: current_user.user_key,
                             append_id: params[:parent_id],
                             search_context: search_context)
      end

      def actor
        @actor ||= Hyrax::CurationConcern.actor
      end

      def actor_environment
        # TODO: just pass a change_set?
        Actors::Environment.new(@change_set.resource, current_ability, resource_params)
      end

      def after_create_error(_obj, _change_set)
        respond_to do |wants|
          wants.html do
            render 'new', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end

      def after_update_error(_obj, change_set)
        respond_to do |wants|
          wants.html do
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: change_set.errors }) }
        end
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

      # Include 'hyrax/base' in the search path for views, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['hyrax/base']
      end

      def contextual_path(presenter, parent_presenter)
        ::Hyrax::ContextualPath.new(presenter, parent_presenter).show
      end

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
        doc = ::SolrDocument.find(params[:id])
        raise WorkflowAuthorizationException if doc.suppressed?
        raise CanCan::AccessDenied.new(nil, :show)
      end

      def render_unavailable
        message = I18n.t("hyrax.workflow.unauthorized")
        respond_to do |wants|
          wants.html do
            unavailable_presenter
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

      def unavailable_presenter
        @presenter ||= show_presenter.new(::SolrDocument.find(params[:id]), current_ability, request)
      end

      def decide_layout
        case action_name
        when 'show'
          theme
        else
          'dashboard'
        end
      end

      def after_create_success(obj, _change_set)
        respond_to do |wants|
          wants.html do
            # Calling `#t` in a controller context does not mark _html keys as html_safe
            flash[:notice] = view_context.t('hyrax.works.create.after_create_html', application_name: view_context.application_name)
            redirect_to [main_app, obj]
          end
          wants.json { render :show, status: :created, location: polymorphic_path([main_app, obj]) }
        end
      end

      def after_update_success(obj, change_set)
        # TODO: we could optimize by making a new query that just returns true if any exist.
        if Hyrax::Queries.find_members(resource: obj, model: ::FileSet).present?
          return redirect_to hyrax.confirm_access_permission_path(obj) if change_set.permissions_changed?
          return redirect_to main_app.confirm_hyrax_permission_path(obj) if change_set.visibility_changed?
        end
        respond_to do |wants|
          wants.html { redirect_to [main_app, obj] }
          wants.json { render :show, status: :ok, location: polymorphic_path([main_app, obj]) }
        end
      end

      def after_delete_success(change_set)
        Hyrax.config.callback.run(:after_destroy, change_set.id, current_user)
        title = change_set.resource.to_s
        respond_to do |wants|
          wants.html { redirect_to my_works_path, notice: "Deleted #{title}" }
          wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
        end
      end

      def additional_response_formats(format)
        format.endnote do
          send_data(presenter.solr_document.export_as_endnote,
                    type: "application/x-endnote-refer",
                    filename: presenter.solr_document.endnote_filename)
        end
      end
  end
end
