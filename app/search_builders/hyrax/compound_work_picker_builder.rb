# frozen_string_literal: true

module Hyrax
  ##
  # Search builder for the compound `work_or_url` sub-property's picker. Finds
  # works *and* collections the current user can read (it subclasses
  # {Hyrax::SearchBuilder}, so permission filtering is retained), matching any
  # indexed query term OR a partial/prefix title.
  #
  # {Hyrax::FilterByType#models} already includes both work and collection
  # classes, so no `only_works?`/`only_collections?` override is needed — the
  # default type filter admits both.
  class CompoundWorkPickerBuilder < Hyrax::SearchBuilder
    include Hyrax::FilterByType
    include Hyrax::PartialTitleQuery

    self.default_processor_chain += [:filter_on_any_term_or_partial_title]

    def initialize(context)
      super(context)
      @q = context.params[:q]
    end

    # ORs a multi-field term match with a prefix-wildcard title match. The rest
    # of the processor chain still applies the permission and type filters.
    def filter_on_any_term_or_partial_title(solr_parameters)
      return if @q.blank?

      solr_parameters[:q] = partial_title_query(@q.to_s.strip)
      solr_parameters[:defType] = 'lucene'
    end
  end
end
