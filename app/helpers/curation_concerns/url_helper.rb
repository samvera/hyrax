module CurationConcerns
  module UrlHelper
    # override Blacklight so we can use our 'curation_concern' namespace
    # We may also pass in a ActiveFedora document instead of a SolrDocument
    def url_for_document(doc, _options = {})
      if doc.collection?
        doc
      else
        polymorphic_path([main_app, :curation_concerns, doc])
      end
    end

    def track_collection_path(*args)
      main_app.track_solr_document_path(*args)
    end

    def track_generic_file_path(*args)
      main_app.track_solr_document_path(*args)
    end

    # generated new GenericWork models get registered as curation concerns and need a
    # track_model_path to render Blacklight-related views
    CurationConcerns.configuration.registered_curation_concern_types.each do |concern|
      define_method("track_#{concern.underscore}_path") { |*args| main_app.track_solr_document_path(*args) }
    end
  end
end
