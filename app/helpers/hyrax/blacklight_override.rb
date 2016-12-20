module Hyrax
  # Overrides of methods defined by the Blacklight gem.
  module BlacklightOverride
    def application_name
      t('hyrax.product_name', default: super)
    end

    # Override Blacklight so we can use the per-worktype routes
    # @param doc [#collection?, #model_name]
    def url_for_document(doc, _options = {})
      return [hyrax, doc] if doc.collection?
      [main_app, doc]
    end
  end
end
