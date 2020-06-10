# frozen_string_literal: true
module Hyrax
  class ManifestHelper
    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes

    def initialize(hostname)
      @hostname = hostname
    end

    def polymorphic_url(record, opts = {})
      opts[:host] ||= @hostname
      super(record, opts)
    end

    # Build a rendering hash
    #
    # @return [Hash] rendering
    def build_rendering(file_set_id)
      file_set_document = query_for_rendering(file_set_id)
      label = file_set_document.label.present? ? ": #{file_set_document.label}" : ''
      mime = file_set_document.mime_type.presence || I18n.t("hyrax.manifest.unknown_mime_text")
      {
        '@id' => Hyrax::Engine.routes.url_helpers.download_url(file_set_document.id, host: @hostname),
        'format' => mime,
        'label' => I18n.t("hyrax.manifest.download_text") + label
      }
    end

    # Query for the properties to create a rendering
    #
    # @return [SolrDocument] query result
    def query_for_rendering(file_set_id)
      ::SolrDocument.find(file_set_id)
    end
  end
end
