module CurationConcerns
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::CollectionsControllerBehavior
    include Blacklight::AccessControls::Catalog

    included do
      before_action :filter_docs_with_read_access!, except: :show
      self.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]
      layout 'curation_concerns/1_column'
      skip_load_and_authorize_resource only: :show
    end

    def new
      super
      form
    end

    def edit
      super
      form
    end

    def show
      presenter
      super
    end

    def after_create_error
      form
      super
    end

    def after_update_error
      form
      query_collection_members
      super
    end

    # overriding the method in Hydra::Collections so the search builder can find the collection
    def collection
      action_name == 'show' ? @presenter : @collection
    end

    protected

      def filter_docs_with_read_access!
        super
        flash.delete(:notice) if flash.notice == 'Select something first'
      end

      def presenter
        @presenter ||= begin
          _, document_list = search_results(params, self.class.search_params_logic + [:find_one])
          curation_concern = document_list.first
          raise CanCan::AccessDenied unless curation_concern
          presenter_class.new(curation_concern, current_ability)
        end
      end

      def presenter_class
        CurationConcerns::CollectionPresenter
      end

      def collection_member_search_builder_class
        CurationConcerns::SearchBuilder
      end

      def collection_params
        form_class.model_attributes(params[:collection])
      end

      def query_collection_members
        params[:q] = params[:cq]
        super
      end

      def after_destroy(id)
        respond_to do |format|
          format.html { redirect_to collections_path, notice: 'Collection was successfully deleted.' }
          format.json { render json: { id: id }, status: :destroyed, location: @collection }
        end
      end

      def form
        @form ||= form_class.new(@collection)
      end

      def form_class
        CurationConcerns::Forms::CollectionEditForm
      end

      # Include 'catalog' and 'curation_concerns/base' in the search path for views
      def _prefixes
        @_prefixes ||= super + ['catalog', 'curation_concerns/base']
      end
  end
end
