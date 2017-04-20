# frozen_string_literal: true

module Hyrax
  class SearchState < Blacklight::SearchState
    include ActionDispatch::Routing::RouteSet::MountedHelpers

    def initialize(view_context)
      super(view_context.params, view_context.blacklight_config)
      @view_context = view_context
    end

    # Required for producing full urls (has the host)
    delegate :url_options, to: :@view_context

    # Override Blacklight so we can use the per-worktype routes
    # @param doc [#collection?, #model_name]
    def url_for_document(doc, _options = {})
      return [hyrax, doc] if doc.collection?
      [main_app, doc]
    end
  end
end
