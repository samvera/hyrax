# frozen_string_literal: true
module Hyrax
  module Forms
    module Widgets
      class AdminSetEmbargoPeriod
        # Visibility options for permission templates
        def options
          i18n_prefix = "hyrax.admin.admin_sets.form_visibility.release.varies.embargo"
          [[Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS, I18n.t('.6mos', scope: i18n_prefix)],
           [Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR, I18n.t('.1yr', scope: i18n_prefix)],
           [Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS, I18n.t('.2yrs', scope: i18n_prefix)],
           [Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_3_YEARS, I18n.t('.3yrs', scope: i18n_prefix)]]
        end
      end
    end
  end
end
