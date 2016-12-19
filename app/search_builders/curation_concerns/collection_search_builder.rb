module CurationConcerns
  # Our parent class is the generated SearchBuilder descending from Blacklight::SearchBuilder
  # It includes Blacklight::Solr::SearchBuilderBehavior, Hydra::AccessControlsEnforcement, CurationConcerns::SearchFilters
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb Blacklight::SearchBuilder parent
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb Blacklight::Solr::SearchBuilderBehavior
  # @see https://github.com/projecthydra/curation_concerns/blob/master/app/search_builders/curation_concerns/README.md SearchBuilders README
  # @note the default_processor_chain defined by Blacklight::Solr::SearchBuilderBehavior provides many possible points of override
  #
  class CollectionSearchBuilder < ::SearchBuilder
    include FilterByType
    # Defines which search_params_logic should be used when searching for Collections
    def initialize(*)
      @rows = 100
      super
    end

    # @return [String] Solr field name indicating default sort order
    def sort_field
      Solrizer.solr_name('title', :sortable)
    end

    # @return [Hash{Symbol => Array[Symbol]}] bottom-up map of "what you need" to "what qualifies"
    # @note i.e., requiring :read access is satisfied by either :read or :edit access
    def access_levels
      { read: [:read, :edit], edit: [:edit] }
    end

    attr_writer :discovery_perms # TODO: remove this line
    ## Overrides

    # unprotect lib/blacklight/access_controls/enforcement.rb methods
    # Remove these when https://github.com/projectblacklight/blacklight-access_controls/pull/23 is merged/released/required
    def discovery_permissions
      @discovery_perms || super
    end

    def discovery_permissions=(*args)
      super
    end

    # This overrides the models in FilterByType
    def models
      collection_classes
    end

    # Sort results by title if no query was supplied.
    # This overrides the default 'relevance' sort.
    def add_sorting_to_solr(solr_parameters)
      return if solr_parameters[:q]
      solr_parameters[:sort] ||= "#{sort_field} asc"
    end
  end
end
