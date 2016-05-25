module CurationConcerns::RightsHelper
  def include_current_value(value, _index, render_options, html_options)
    unless value.blank? || RightsService.active?(value)
      html_options[:class] << ' force-select'
      render_options += [[RightsService.label(value), value]]
    end
    [render_options, html_options]
  end
end
