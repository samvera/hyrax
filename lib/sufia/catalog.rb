module Sufia
  module Catalog
    extend ActiveSupport::Concern
    included do
      self.solr_search_params_logic += [:only_generic_files]
    end

    def index
      setup_front_page unless has_search_parameters? 
      super
    end

    protected
      def setup_front_page
        @featured_researcher = ContentBlock.find_or_create_by(name: 'featured_researcher')
        @featured_works = FeaturedWork.generic_files
        recent
        recent_me # also grab my recent docs too
      end

      def recent
        if user_signed_in?
          # grab other people's documents
          (_, @recent_documents) = get_search_results(:q =>filter_not_mine,
                                            :sort=>sort_field, :rows=>4)
        else
          # grab any documents we do not know who you are
          (_, @recent_documents) = get_search_results(:q =>'', :sort=>sort_field, :rows=>4)
        end
      end

      def recent_me
        if user_signed_in?
          (_, @recent_user_documents) = get_search_results(:q =>filter_mine,
                                            :sort=>sort_field, :rows=>4)
        end
      end

      def filter_not_mine
        "{!lucene q.op=AND df=#{depositor}}-#{current_user.user_key}"
      end

      def filter_mine
        "{!lucene q.op=AND df=#{depositor}}#{current_user.user_key}"
      end

      def depositor
        Solrizer.solr_name('depositor', :stored_searchable, type: :string)
      end

      def sort_field
        "#{Solrizer.solr_name('system_create', :sortable)} desc"
      end

      # Limits search results just to GenericFiles
      # @param solr_parameters the current solr parameters
      # @param user_parameters the current user-subitted parameters
      def only_generic_files(solr_parameters, user_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:\"info:fedora/afmodel:GenericFile\""
      end

  end
end
