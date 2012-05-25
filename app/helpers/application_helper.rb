module ApplicationHelper

  def javascript(*files)
    content_for(:js_head) { javascript_include_tag(*files) }
  end

  def stylesheet(*files)
    content_for(:css_head) { stylesheet_link_tag(*files) }
  end

end
