# frozen_string_literal: true
module Hyrax
  # Overrides of methods defined by the Blacklight gem.
  module BlacklightOverride
    def application_name
      t('hyrax.product_name', default: super)
    end

    def index_field_label(document, field)
      field_config = index_fields(document)[field]
      return field_config.label if field_config&.custom_label
      field_label(
        :"blacklight.search.fields.index.#{field}",
        :"blacklight.search.fields.#{field}",
        (field_config.label if field_config),
        field.to_s.humanize
      )
    end
  end
end
