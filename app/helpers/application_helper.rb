# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    return "no display name" unless recent_document[:depositor_t]
    return User.where(:login => recent_document[:depositor_t][0]).name rescue recent_document[:depositor_t][0]
  end

  def get_depositor_from_document(doc)
    doc[:depositor_t] ? doc[:depositor_t][0] : "no depositor value"
  end

  def link_to_facet(field, field_string)
    link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
  end

  def link_to_facet_list(list, field_string, emptyText="No value entered", separator=", ")
    return list.map{ |item| link_to_facet(item, field_string) }.join(separator) unless list.blank?
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
    user = User.find_by_login(login)
    link_to user.name, profile_path(login)
  rescue
    link_to login, profile_path(login)
  end

  def linkify_chat_id(chat_id)
    if chat_id.end_with? '@chat.psu.edu'
      "<a href=\"xmpp:#{chat_id}\">#{chat_id}</a>"
    else
      chat_id
    end
  end
end
