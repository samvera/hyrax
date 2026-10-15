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

    self.default_processor_chain += [:filter_on_any_term_or_partial_title, :exclude_current_work]

    def initialize(context)
      super(context)
      @q = context.params[:q]
      @exclude_id = context.params[:exclude_id]
    end

    # Keep the work being edited out of its own picker: relating a work to itself is
    # meaningless, and it is otherwise one click away. Mirrors
    # Hyrax::My::FindWorksSearchBuilder#show_only_other_works.
    def exclude_current_work(solr_parameters)
      return if @exclude_id.blank?

      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += ["-#{Hyrax::SolrQueryBuilderService.construct_query_for_ids([@exclude_id])}"]
    end

    # ORs a multi-field term match with a prefix-wildcard title match, plus an
    # exact id match so a pasted work id resolves to that work (and so the picker
    # shows its title rather than leaving the id unresolvable). The rest of the
    # processor chain still applies the permission and type filters.
    def filter_on_any_term_or_partial_title(solr_parameters)
      return if @q.blank?

      term = @q.to_s.strip
      solr_parameters[:q] = "#{partial_title_query(term)} OR #{id_clause(term)}"
      solr_parameters[:defType] = 'lucene'
    end

    private

    # Added here rather than to PartialTitleQuery::QUERY_FIELDS, which
    # My::FindWorksSearchBuilder also uses: only this picker needs to accept an id.
    def id_clause(term)
      %(id:"#{escape(term)}")
    end
  end
end
