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

    # The SPARQL gem stomps on the Rails definition of deep_dup and gives us a Hash instead of
    # a HashWithIndifferentAccess. This is an ugly workaround to get the right contract with
    # the upstream class.
    # https://github.com/ruby-rdf/sparql/blob/develop/lib/sparql/algebra/extensions.rb#L238-L244
    def to_hash
      super.with_indifferent_access
    end
    alias to_h to_hash
  end
end
