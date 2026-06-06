# frozen_string_literal: true

module Hyrax
  ##
  # Search builder for the compound `work_or_url` sub-property's work picker. Finds
  # works the current user can read (it subclasses {Hyrax::SearchBuilder}, so
  # permission filtering is retained), matching any indexed query term OR a
  # partial/prefix title.
  class CompoundWorkPickerBuilder < Hyrax::SearchBuilder
    include Hyrax::FilterByType

    self.default_processor_chain += [:filter_on_any_term_or_partial_title]

    def initialize(context)
      super(context)
      @q = context.params[:q]
    end

    def only_works?
      true
    end

    # ORs a multi-field term match with a prefix-wildcard title match. The rest
    # of the processor chain still applies the permission and type filters.
    def filter_on_any_term_or_partial_title(solr_parameters)
      return if @q.blank?

      term = @q.to_s.strip
      solr_parameters[:q] = "#{multi_field_clause(term)} OR #{prefix_title_clause(term)}"
      solr_parameters[:defType] = 'lucene'
    end

    private

    def multi_field_clause(term)
      escaped = escape(term)
      QUERY_FIELDS.map { |field| "#{field}:(#{escaped})" }.join(' OR ')
    end

    # Prefix-wildcard on each whitespace-separated token of the title, e.g.
    # "jour stud" -> title_tesim:(jour* AND stud*).
    def prefix_title_clause(term)
      tokens = term.split(/\s+/).reject(&:empty?).map { |t| "#{escape_token(t)}*" }
      return '' if tokens.empty?
      "title_tesim:(#{tokens.join(' AND ')})"
    end

    QUERY_FIELDS = %w[title_tesim description_tesim creator_tesim keyword_tesim].freeze

    # Escape Solr/Lucene special characters in a phrase (wildcards included —
    # the multi-field clause is not a prefix search).
    def escape(value)
      value.to_s.gsub(%r{([+\-&|!(){}\[\]^"~*?:\\/])}, '\\\\\1')
    end

    # Escape special characters in a single token but keep it usable as a
    # prefix (the trailing `*` is added by the caller, not escaped here).
    def escape_token(value)
      value.to_s.gsub(%r{([+\-&|!(){}\[\]^"~?:\\/])}, '\\\\\1')
    end
  end
end
