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
      doc = indexed_doc_for(id)
      [doc ? title_from(doc, id) : id.to_s, path_for_doc(doc, id)]
    end

    ##
    # Resolve an internal id to its display title and show path, but only when a
    # matching record is actually indexed. Returns nil when nothing matches, so
    # callers can render a bare, unlinked value rather than a broken link to a
    # non-existent record.
    #
    # @param id [String]
    # @return [Array(String, String), nil] `[title, path]`, or nil when unresolved
    def self.resolve(id)
      doc = indexed_doc_for(id)
      return nil if doc.nil?
      [title_from(doc, id), path_for_doc(doc, id)]
    end

    def self.title_for(id)
      doc = indexed_doc_for(id)
      doc ? title_from(doc, id) : id.to_s
    end

    def self.path_for(id)
      doc = indexed_doc_for(id)
      path_for_doc(doc, id)
    end

    # The indexed Solr document for an id (as a {SolrDocument} so it carries the
    # Wings-aware model resolution), or nil when none is indexed (distinguishes
    # "resolved to a real record" from "no match").
    def self.indexed_doc_for(id)
      raw = Hyrax::SolrService.query("{!field f=id}#{id}", fl: 'id,title_tesim,has_model_ssim', rows: 1).first
      raw && ::SolrDocument.new(raw)
    rescue StandardError => e
      Hyrax.logger.debug("CompoundWorkResolver.indexed_doc_for(#{id}): #{e.message}")
      nil
    end
    private_class_method :indexed_doc_for

    def self.title_from(doc, id)
      Array(doc['title_tesim']).first.presence || id.to_s
    end
    private_class_method :title_from

    # The show path for an indexed record. Classification uses the document's
    # own Wings-aware predicates (`collection?`/`work?`, which resolve through
    # `hydra_model` and so honor the `valkyrie_transition` mapping):
    #   * a collection -> the engine collection show route (`/collections/:id`);
    #   * a work -> its work show route, named by the routed model's
    #     `singular_route_key` (e.g. `hyrax_generic_work_path` ->
    #     `/concern/generic_works/:id`);
    #   * anything else -> the model-agnostic catalog route.
    def self.path_for_doc(doc, id)
      app = Rails.application.routes.url_helpers
      return app.solr_document_path(id) if doc.nil?

      if doc.collection?
        Hyrax::Engine.routes.url_helpers.collection_path(id)
      elsif doc.work?
        helper = "#{doc.hydra_model.model_name.singular_route_key}_path"
        app.respond_to?(helper) ? app.public_send(helper, id) : app.solr_document_path(id)
      else
        app.solr_document_path(id)
      end
    rescue StandardError => e
      Hyrax.logger.debug("CompoundWorkResolver.path_for_doc(#{id}): #{e.message}")
      Rails.application.routes.url_helpers.solr_document_path(id)
    end
    private_class_method :path_for_doc
  end
end
