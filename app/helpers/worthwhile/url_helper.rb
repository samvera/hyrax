module Worthwhile
  module UrlHelper

    # override Blacklight so we can use our 'curation_concern' namespace
    def url_for_document doc, options = {}
      if doc.collection?
        doc
      else
        polymorphic_path([:curation_concern, doc])
      end
    end 
  end
end
