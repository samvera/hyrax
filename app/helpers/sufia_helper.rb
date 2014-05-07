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

  def has_collection_search_parameters?
    !params[:cq].blank?
  end

  def display_user_name(recent_document)
    return "no display name" unless recent_document.depositor
    return User.find_by_user_key(recent_document.depositor).name rescue recent_document.depositor
  end

  def number_of_deposits(user)
    ActiveFedora::Base.where(Solrizer.solr_name('depositor', :stored_searchable) => user.user_key).count
  end

  def link_to_facet(field, field_string)
    link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
  end

  # @param values [Array] The values to display
  # @param solr_field [String] The name of the solr field to link to without its suffix (:facetable) 
  # @param empty_message [String] ('No value entered') The message to display if no values are passed in.
  # @param separator [String] (', ') The value to join with. 
  def link_to_facet_list(values, solr_field, empty_message="No value entered", separator=", ")
    return empty_message if values.blank?
    facet_field = Solrizer.solr_name(solr_field, :facetable)
    safe_join(values.map{ |item| link_to_facet(item, facet_field) }, separator)
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

  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  # We should be able to do away with this method in Blacklight 5
  # @example
  #   link_back_to_catalog(:label=>'Back to Search')
  def link_back_to_catalog(opts={:label=>nil})
    scope = opts.delete(:route_set) || self
    query_params = current_search_session.try(:query_params) || {}
    link_url = scope.url_for(query_params)
    opts[:label] ||= t('blacklight.back_to_search')
    link_to opts[:label], link_url
  end
end
