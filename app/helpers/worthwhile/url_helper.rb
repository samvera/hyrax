module Worthwhile
  module UrlHelper

    # override Blacklight so we can use our 'curation_concern' namespace
    # We may also pass in a ActiveFedora document instead of a SolrDocument
    def url_for_document doc, options = {}
      if doc.kind_of? Worthwhile::GenericFile
        curation_concern_generic_file_path(doc)
      elsif doc.collection?
        doc
      else
        polymorphic_path([:curation_concern, doc])
      end
    end 
  end
end
