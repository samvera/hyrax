
module SufiaHelper

  # link_back_to_dashboard(:label=>'Back to Search')
  # Create a link back to the dashboard screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_dashboard(opts={:label=>'Back to Search'})
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    link_url = dashboard_index_path + "?" + query_params.to_query
    link_to opts[:label], link_url
  end

  def link_to_dashboard_query(query)
    p = params.dup
    p.delete :page
    p.delete :action
    p[:q]=query
    link_url = dashboard_index_path(p)
    link_to(query, link_url)
  end

  def display_user_name(recent_document)
    return "no display name" unless recent_document.depositor
    return User.find_by_user_key(recent_document.depositor).name rescue recent_document.depositor
  end

  def number_of_deposits(user)
    ActiveFedora::SolrService.query("#{Solrizer.solr_name('depositor', :stored_searchable, :type => :string)}:#{user.user_key}").count
  end

  def link_to_facet(field, field_string)
    link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
  end

  def link_to_facet_list(list, field_string, emptyText="No value entered", separator=", ")
    facet_field = Solrizer.solr_name(field_string, :facetable)
    return list.map{ |item| link_to_facet(item, facet_field) }.join(separator) unless list.blank?
    return emptyText
  end


  def link_to_field(fieldname, fieldvalue, displayvalue = nil)
    p = {:search_field=>'advanced', fieldname=>'"'+fieldvalue+'"'}
    link_url = catalog_index_path(p)
    display = displayvalue.blank? ? fieldvalue: displayvalue
    link_to(display, link_url)
  end

  def iconify_auto_link(text, showLink = true)
    auto_link(text) do |value|
      link = "<i class='icon-external-link'></i>&nbsp;#{value}<br />" if showLink
      link = "<i class='icon-external-link'></i>&nbsp;<br />" unless showLink
      link
    end
  end

  def link_to_profile(login)
    user = User.find_by_user_key(login)
    return login if user.nil?

    text = if user.respond_to? :name
      user.name
    else
      login
    end

    link_to text, Sufia::Engine.routes.url_helpers.profile_path(user)
  end

  def linkify_chat_id(chat_id)
    if chat_id.end_with? '@chat.psu.edu'
      "<a href=\"xmpp:#{chat_id}\">#{chat_id}</a>"
    else
      chat_id
    end
  end

  # Override to remove the label class (easier integration with bootstrap)
  # and handles arrays
  def render_facet_value(facet_solr_field, item, options ={})
    logger.warn "display value #{ facet_display_value(facet_solr_field, item)}"
    if item.is_a? Array
      render_array_facet_value(facet_solr_field, item, options)
    end
    if params[:controller] == "dashboard"
      path = sufia.url_for(add_facet_params_and_redirect(facet_solr_field,item.value ).merge(:only_path=>true))
      path = sufia.url_for(add_facet_params_and_redirect(facet_solr_field,item.value ).merge(:only_path=>true))
      (link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
    else
      # This is for controllers that use this helper method that are defined outside Sufia
      path = url_for(add_facet_params_and_redirect(facet_solr_field, item.value).merge(:only_path=>true))
      (link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
    end
  end

    # link_back_to_catalog(:label=>'Back to Search')
  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>t('blacklight.back_to_search')})
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    link_url = sufia.url_for(query_params)
    link_to opts[:label], link_url
  end
end
