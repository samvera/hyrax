# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Helpers for the `work_or_url` compound sub-field, whose stored value is
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

    def self.title_for(id)
      doc = Hyrax::SolrService.query("{!field f=id}#{id}", fl: 'title_tesim', rows: 1).first
      Array(doc&.fetch('title_tesim', nil)).first.presence || id.to_s
    rescue StandardError => e
      Hyrax.logger.debug("CompoundWorkResolver.title_for(#{id}): #{e.message}")
      id.to_s
    end

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
