# frozen_string_literal: true
module Hyrax
  class SearchState < Blacklight::SearchState
    delegate :hyrax, :main_app, to: :controller

    # Override Blacklight so we can use the per-worktype routes
    # @param doc [#collection?, #model_name]
    def url_for_document(doc, _options = {})
      return [hyrax, doc] if doc.collection?
      [main_app, doc]
    end
  end
end
