# frozen_string_literal: true

module Hyrax
  ##
  # Gives a controller that copies `CatalogController`'s Blacklight config the flexible metadata
  # profile's search fields.
  #
  # Such a controller calls `copy_blacklight_config_from(::CatalogController)` once, when its class
  # loads, but `Hyrax::FlexibleCatalogBehavior` loads the profile into `CatalogController` per
  # request. A copy taken before the first catalog request, which is always the case when eager
  # loading, lacks the profile's label facets, search result fields and keyword search fields, so
  # show-page term links fall back to filtering on stored ids.
  #
  # With flexible metadata on, each request's config takes those facet, index and search fields from
  # the freshly loaded catalog config, keeping the controller's other settings, such as its search
  # builder. It also answers `render_optionally?`, the condition the profile's search result fields
  # name, by asking the catalog's own implementation.
  #
  # In either mode it builds facet links with `main_app.search_catalog_url`. Blacklight's default calls
  # `search_catalog_url` against Hyrax's engine routes, which have no catalog route, so Rails falls
  # back to a route it can fill from the page's own `:id` and the link misses the catalog.
  module FlexibleCatalogConfigCopy
    PROFILE_DRIVEN_FIELDS = %i[facet_fields index_fields search_fields].freeze

    def blacklight_config
      @blacklight_config ||= super.tap do |config|
        next unless Hyrax.config.flexible? && ::CatalogController.respond_to?(:load_flexible_schema)

        ::CatalogController.load_flexible_schema
        catalog = ::CatalogController.blacklight_config.deep_copy
        PROFILE_DRIVEN_FIELDS.each { |fields| config.public_send("#{fields}=", catalog.public_send(fields)) }
      end
    end

    private

    def render_optionally?(*args)
      Blacklight::Configuration::Context.new(catalog_field_conditions)
                                        .evaluate_configuration_conditional(:render_optionally?, *args)
    end

    def catalog_field_conditions
      @catalog_field_conditions ||= ::CatalogController.allocate.tap { |catalog| catalog.request = request }
    end

    def search_action_url(options = {})
      main_app.search_catalog_url(options.except(:controller, :action))
    end
  end
end
