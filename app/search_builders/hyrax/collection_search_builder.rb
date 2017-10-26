module Hyrax
  # Our parent class is the generated SearchBuilder descending from Blacklight::SearchBuilder
  # It includes Blacklight::Solr::SearchBuilderBehavior, Hydra::AccessControlsEnforcement, Hyrax::SearchFilters
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb Blacklight::SearchBuilder parent
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb Blacklight::Solr::SearchBuilderBehavior
  # @see https://github.com/samvera/hyrax/blob/master/app/search_builders/hyrax/README.md SearchBuilders README
  # @note the default_processor_chain defined by Blacklight::Solr::SearchBuilderBehavior provides many possible points of override
  #
  class CollectionSearchBuilder < ::SearchBuilder
    # @return [String] Solr field name indicating default sort order
    def sort_field
      Solrizer.solr_name('title', :sortable)
    end

    # Sort results by title if no query was supplied.
    # This overrides the default 'relevance' sort.
    def add_sorting_to_solr(solr_parameters)
      return if solr_parameters[:q]
      solr_parameters[:sort] ||= "#{sort_field} asc"
    end

    def by_depositor(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!field f=#{DepositSearchBuilder.depositor_field} v=#{blacklight_params[:depositor]}}" if blacklight_params[:depositor].present?
    end

    private

      def only_collections?
        true
      end
  end
end
