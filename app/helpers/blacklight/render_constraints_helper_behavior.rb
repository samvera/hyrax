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

module Blacklight::RenderConstraintsHelperBehavior

  # Render actual constraints, not including header or footer
  # info. 
  def render_constraints(localized_params = params)
    (render_constraints_query(localized_params) + render_constraints_filters(localized_params)).html_safe
  end 
  
  def render_constraints_query(localized_params = params)
    # So simple don't need a view template, we can just do it here.
    if (!localized_params[:q].blank?)
      label = 
        if (localized_params[:search_field].blank? || (default_search_field && localized_params[:search_field] == default_search_field[:key] ) ) 
          nil 
        else
          label_for_search_field(localized_params[:search_field])
        end 
      if params[:controller] == 'dashboard'       
        render_constraint_element(label,
            localized_params[:q], 
            :classes => ["query"], 
            :remove => dashboard_path(localized_params.merge(:q=>nil, :action=>'index')))
      else
        render_constraint_element(label,
            localized_params[:q], 
            :classes => ["query"], 
            :remove => catalog_index_path(localized_params.merge(:q=>nil, :action=>'index')))
      end
    else
      "".html_safe
    end 
  end 

  def render_constraints_filters(localized_params = params)
     return "".html_safe unless localized_params[:f]
     content = []
     localized_params[:f].each_pair do |facet,values|
       content << render_filter_element(facet, values, localized_params)
     end 

     return content.flatten.join("\n").html_safe    
  end 

  def render_filter_element(facet, values, localized_params)
    values.map do |val|
      if params[:controller] == 'dashboard'       
        render_constraint_element( facet_field_labels[facet],
                  val, 
                  :remove => dashboard_path(remove_facet_params(facet, val, localized_params)),
                  :classes => ["filter", "filter-" + facet.parameterize] 
                ) + "\n"    
      else
        render_constraint_element( facet_field_labels[facet],
                  val, 
                  :remove => catalog_index_path(remove_facet_params(facet, val, localized_params)),
                  :classes => ["filter", "filter-" + facet.parameterize] 
                ) + "\n"    
      end
    end 
  end 

  # Render a label/value constraint on the screen. Can be called
  # by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired,
  # although in most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # options:
  # [:remove]
  #    url to execute for a 'remove' action  
  # [:classes] 
  #    can be an array of classes to add to container span for constraint.
  # [:escape_label]
  #    default true, HTML escape.
  # [:escape_value]
  #    default true, HTML escape. 
  def render_constraint_element(label, value, options = {})
    render(:partial => "catalog/constraints_element", :locals => {:label => label, :value => value, :options => options})
  end

end
