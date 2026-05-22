# frozen_string_literal: true

module Hyrax
  # Returns the canonical, UUID-based path for a Hyrax resource
  # (e.g. '/concern/generic_works/<uuid>' or '/collections/<uuid>').
  #
  # Collections are routed by the Hyrax engine; works are routed by the
  # host app's curation-concern resources, so the picker consults
  # `resource.collection?` to choose the right route helper.
  module PermalinkPath
    module_function

    # @param resource [#collection?] a Hyrax::Resource (work or collection)
    # @return [String] the canonical path, e.g. '/concern/generic_works/<uuid>'
    def call(resource)
      helpers = collection_resource?(resource) ? Hyrax::Engine.routes.url_helpers : Rails.application.routes.url_helpers
      helpers.polymorphic_path(resource)
    end

    def collection_resource?(resource)
      resource.respond_to?(:collection?) && resource.collection?
    end
    private_class_method :collection_resource?
  end
end
