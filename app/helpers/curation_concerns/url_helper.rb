module CurationConcerns
  module UrlHelper
    # override Blacklight so we can use our 'curation_concern' namespace
    # We may also pass in a ActiveFedora document instead of a SolrDocument
    def url_for_document(doc, _options = {})
      if doc.collection?
        doc
      else
        polymorphic_path([main_app, doc])
      end
    end

    # generated models get registered as curation concerns and need a
    # track_model_path to render Blacklight-related views
    (['FileSet', 'Collection'] + CurationConcerns.config.registered_curation_concern_types).each do |concern|
      define_method("track_#{concern.constantize.model_name.singular_route_key}_path") { |*args| main_app.track_solr_document_path(*args) }
    end
  end
end
