# frozen_string_literal: true

module Hyrax
  ##
  # Builds the Solr query a work picker uses for partial, as-you-type matching:
  # an indexed term match across a few fields OR a prefix-wildcard title match,
  # so a partial word ("repel", "jour stud") finds works before the full title is
  # typed. Shared by the pickers that need it ({Hyrax::CompoundWorkPickerBuilder}
  # and {Hyrax::My::FindWorksSearchBuilder}); set it on `solr_parameters[:q]` with
  # `defType: 'lucene'`.
  module PartialTitleQuery
    extend ActiveSupport::Concern

    QUERY_FIELDS = %w[title_tesim description_tesim creator_tesim keyword_tesim].freeze

    protected

    # @param term [String] the typed search term
    # @return [String] a lucene query: the term matched across {QUERY_FIELDS} OR a
    #   prefix-wildcard match on each title token.
    def partial_title_query(term)
      "#{multi_field_clause(term)} OR #{prefix_title_clause(term)}"
    end

    private

    def multi_field_clause(term)
      escaped = escape(term)
      QUERY_FIELDS.map { |field| "#{field}:(#{escaped})" }.join(' OR ')
    end

    # Prefix-wildcard on each whitespace-separated title token, e.g.
    # "jour stud" -> title_tesim:(jour* AND stud*).
    def prefix_title_clause(term)
      tokens = term.split(/\s+/).reject(&:empty?).map { |t| "#{escape_token(t)}*" }
      return '' if tokens.empty?

      "title_tesim:(#{tokens.join(' AND ')})"
    end

    # Escape Solr/Lucene special characters in a phrase (wildcards included — the
    # multi-field clause is not a prefix search).
    def escape(value)
      value.to_s.gsub(%r{([+\-&|!(){}\[\]^"~*?:\\/])}, '\\\\\1')
    end

    # Escape special characters in a single token but keep it usable as a prefix
    # (the trailing `*` is added by the caller, not escaped here).
    def escape_token(value)
      value.to_s.gsub(%r{([+\-&|!(){}\[\]^"~?:\\/])}, '\\\\\1')
    end
  end
end
