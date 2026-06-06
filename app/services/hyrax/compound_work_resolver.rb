# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Helpers for the `work_or_url` compound sub-property, whose stored value is
  # either an external URL or an internal work id. Distinguishes the two and
  # resolves an internal work id to a display title (from Solr) and a show path.
  class CompoundWorkResolver
    # A value is an external URL when it has an http(s) scheme; Valkyrie ids
    # never do.
    def self.url?(value)
      value.to_s.match?(%r{\Ahttps?://}i)
    end

    ##
    # @param id [String] an internal work id
    # @return [Array(String, String)] the work's title (falling back to the id)
    #   and its show path
    def self.title_and_path(id)
      [title_for(id), path_for(id)]
    end

    ##
    # Resolve an internal work id to its display title and show path, but only
    # when a matching work is actually indexed. Returns nil when nothing
    # matches, so callers can render a bare, unlinked value rather than a broken
    # link to a non-existent work.
    #
    # @param id [String]
    # @return [Array(String, String), nil] `[title, path]`, or nil when unresolved
    def self.resolve(id)
      title = indexed_title_for(id)
      return nil if title.nil?
      [title, path_for(id)]
    end

    def self.title_for(id)
      indexed_title_for(id) || id.to_s
    end

    # The indexed title for a work id, or nil when no such work is indexed
    # (distinguishes "resolved to a real work" from "no match").
    def self.indexed_title_for(id)
      doc = Hyrax::SolrService.query("{!field f=id}#{id}", fl: 'title_tesim', rows: 1).first
      return nil if doc.nil?
      Array(doc['title_tesim']).first.presence || id.to_s
    rescue StandardError => e
      Hyrax.logger.debug("CompoundWorkResolver.indexed_title_for(#{id}): #{e.message}")
      nil
    end
    private_class_method :indexed_title_for

    # The model-agnostic Blacklight show route (`/catalog/:id`) links any
    # indexed work without knowing its class.
    def self.path_for(id)
      Rails.application.routes.url_helpers.solr_document_path(id)
    rescue StandardError => e
      Hyrax.logger.debug("CompoundWorkResolver.path_for(#{id}): #{e.message}")
      "/catalog/#{id}"
    end
  end
end
