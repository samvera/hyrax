module Hyrax
  class SearchState < Blacklight::SearchState
    include ActionDispatch::Routing::RouteSet::MountedHelpers

    # Override Blacklight so we can use the per-worktype routes
    # @param doc [#collection?, #model_name]
    def url_for_document(doc, _options = {})
      return [hyrax, doc] if doc.collection?
      [main_app, doc]
    end
  end
end
