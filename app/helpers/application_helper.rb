module ApplicationHelper

  def javascript(*files)
    content_for(:js_head) { javascript_include_tag(*files) }
  end

  def stylesheet(*files)
    content_for(:css_head) { stylesheet_link_tag(*files) }
  end

  # link_back_to_dashboard(:label=>'Back to Search')
  # Create a link back to the dashboard screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_dashboard(opts={:label=>'Back to Search'})
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    link_url = dashboard_path + "?" + query_params.to_query
    link_to opts[:label], link_url
  end

  def link_to_dashboard_query(query)
    p = params.dup
    p.delete :page
    p.delete :action
    p[:q]=query
    link_url = dashboard_path(p)
    link_to(query, link_url)
  end

  def display_user_name(recent_document)
     return User.display_name( recent_document[:depositor_t][0]) if recent_document[:depositor_t] 
  end

  def link_to_facet(field, field_string)
      link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
  end

  def link_to_facet_list(list, field_string, emptyText="No value entered", seperator=", ")  
      return list.map{ |item| link_to_facet(item, field_string) }.join(seperator) unless list.blank?
      return emptyText
  end


  def link_to_field(fieldname, fieldvalue, displayvalue = nil)
      p = {:search_field=>'advanced', fieldname=>fieldvalue}
      link_url = catalog_index_path(p)
      display = displayvalue.blank? ? fieldvalue: displayvalue
      link_to(display, link_url)
  end

end
