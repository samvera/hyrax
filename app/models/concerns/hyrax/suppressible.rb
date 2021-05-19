# frozen_string_literal: true
module Hyrax
  # A work should be able to be filtered out of search results if it's inactive
  module Suppressible
    extend ActiveSupport::Concern

    included do
      # This holds the workflow state
      property :state, predicate: Vocab::FedoraResourceStatus.objState, multiple: false
    end

    ##
    # @deprecated use `Hyrax::ResourceStatus` instead. in most cases,
    #   {#suppressed?} is being called on a {SolrDocumentBehavior}. we continue
    #   to index `suppressed_bsi` and expose its value as an attribute on solr
    #   document objects.
    #
    # Used to restrict visibility on search results for a work that is inactive. If the state is not set, the
    # default behavior is to consider the work not to be suppressed.
    #
    # Override this method if you have some criteria by which records should not display in the search results.
    def suppressed?
      Hyrax::ResourceStatus.new(resource: self).inactive?
    end

    ##
    # @deprecated Use `Sipity::Entity(entity)` instead.
    def to_sipity_entity
      Deprecation.warn "Use `Sipity::Entity(entity)` instead."
      raise "Can't create an entity until the model has been persisted" unless persisted?
      @sipity_entity ||= Sipity::Entity(to_global_id)
    end
  end
end
