module Hyrax
  module Renderers
    class LinkedAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          link_to(ERB::Util.h(value), search_path(value))
        end

        def search_path(value)
          Rails.application.routes.url_helpers.search_catalog_path(
            search_field: search_field, q: ERB::Util.h(value), locale: I18n.locale
          )
        end

        def search_field
          options.fetch(:search_field, field)
        end
    end
  end
end
