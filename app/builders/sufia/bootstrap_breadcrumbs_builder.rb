# The BootstrapBreadcrumbsBuilder is a Bootstrap compatible breadcrumb builder.
# It provides basic functionalities to render a breadcrumb navigation according to Bootstrap's conventions.
#
# BootstrapBreadcrumbsBuilder accepts a limited set of options:
#
# You can use it with the :builder option on render_breadcrumbs:
#     <%= render_breadcrumbs builder: Sufia::BootstrapBreadcrumbsBuilder %>
#
class Sufia::BootstrapBreadcrumbsBuilder < BreadcrumbsOnRails::Breadcrumbs::Builder
  include ActionView::Helpers::OutputSafetyHelper
  def render
    if @elements.blank?
      return ""
    end

    @context.content_tag(:ul, class: 'breadcrumb') do
      safe_join(@elements.uniq.collect {|e| render_element(e)})
    end 
  end

  def render_element(element)
    html_class = 'active' if @context.current_page?(compute_path(element))

    @context.content_tag(:li, class: html_class) do
      @context.link_to_unless_current(@context.truncate(compute_name(element), length: 30, separator: ' '), compute_path(element), element.options)
    end
  end
end
