# @deprecated no longer used.  Will be removed no later than release 6.x
# Custom pagination renderer
# Call using will_paginate(@results, :renderer => 'PrevNextLinks')
require 'deprecation'
class PrevNextLinks < WillPaginate::LinkRenderer
  extend Deprecation
  
  self.deprecation_horizon = 'hydra-head 5.x'

  def initialize(app)
    Deprecation.warn(PrevNextLinks, "PrevNextLinks has been deprecated; it will be removed from HydraHead no later than release 6.")
    @app = app
  end

  def to_html
    links = []
    links << page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])
    if @collection.size < 1
      links << "<b>0&nbsp;-&nbsp;0</b> of <b>0</b>"
    else
      links << %{<b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>} % [
        @collection.start + 1,
        @collection.start + @collection.length,
        @collection.total
      ]
    end
    links << page_link_or_span(@collection.next_page, 'disabled next_page', @options[:next_label])
    html = links.join(@options[:separator])
    @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
  end
  deprecation_deprecate :to_html
  
end