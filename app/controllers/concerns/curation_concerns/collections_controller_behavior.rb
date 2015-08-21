module CurationConcerns
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::CollectionsControllerBehavior

    included do
      before_action :filter_docs_with_read_access!, except: :show
      self.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]
      layout 'curation_concerns/1_column'
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
      super
      presenter
    end

    protected

      def presenter
        @presenter ||= presenter_class.new(@collection)
      end

      def presenter_class
        CurationConcerns::CollectionPresenter
      end

      def collection_member_search_builder_class
        CurationConcerns::SearchBuilder
      end

      def collection_params
        form_class.model_attributes(
          params.require(:collection).permit(:title, :description, :members, part_of: [],
                                                                             contributor: [], creator: [], publisher: [], date_created: [], subject: [],
                                                                             language: [], rights: [], resource_type: [], identifier: [], based_near: [],
                                                                             tag: [], related_url: [])
        )
      end

      def query_collection_members
        flash[:notice] = nil if flash[:notice] == 'Select something first'
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
