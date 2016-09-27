module CurationConcerns::RightsHelper
  extend Deprecation
  self.deprecation_horizon = 'curation_concerns version 2.0.0'

  def include_current_value(value, _index, render_options, html_options)
    unless value.blank? || RightsService.active?(value)
      html_options[:class] << ' force-select'
      render_options += [[RightsService.label(value), value]]
    end
    [render_options, html_options]
  end
  deprecation_deprecate include_current_value: 'use LicenseService#include_current_value instead'
end
