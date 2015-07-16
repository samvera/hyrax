module CurationConcerns
  module UrlHelper

    # override Blacklight so we can use our 'curation_concern' namespace
    # We may also pass in a ActiveFedora document instead of a SolrDocument
    def url_for_document doc, options = {}
      if Hydra::Works.generic_file?(doc)
        main_app.curation_concerns_generic_file_path(doc)
      elsif doc.collection?
        doc
      else
        polymorphic_path([main_app, :curation_concerns, doc])
      end
    end

    def track_collection_path(*args)
      main_app.track_solr_document_path(*args)
    end

    def track_generic_work_path(*args)
      main_app.track_solr_document_path(*args)
    end

    def track_generic_file_path(*args)
      main_app.track_solr_document_path(*args)
    end
  end
end
