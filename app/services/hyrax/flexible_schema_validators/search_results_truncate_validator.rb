# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Warns when a property declares `view: { search_results_truncate: N }`
    # without `view: { render_as: html }`. The truncation length is only honored
    # by `render_html_index_value`, which is wired solely for `render_as: html`
    # fields, so on any other field the setting is carried but never read - a
    # silent no-op.
    class SearchResultsTruncateValidator
      def initialize(profile, warnings)
        @profile = profile
        @warnings = warnings
      end

      def validate!
        (@profile['properties'] || {}).each do |name, config|
          next unless config.is_a?(Hash)

          view = config['view']
          next unless view.is_a?(Hash) && view.key?('search_results_truncate')
          next if view['render_as'].to_s == 'html'

          @warnings << I18n.t(
            'hyrax.flexible_schema_validators.search_results_truncate_validator.warnings.requires_html',
            property: name
          )
        end
      end
    end
  end
end
