# frozen_string_literal: true
module Hyrax
  module Forms
    module Widgets
      class AdminSetVisibility
        # Visibility options for permission templates
        def options
          i18n_prefix = "hyrax.admin.admin_sets.form_visibility.visibility"
          # Note: Visibility 'varies' = '' implies no constraints
          [[Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, I18n.t('.everyone', scope: i18n_prefix)],
           ['', I18n.t('.varies', scope: i18n_prefix)],
           [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, I18n.t('.institution', scope: i18n_prefix)],
           [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, I18n.t('.restricted', scope: i18n_prefix)]]
        end
      end
    end
  end
end
