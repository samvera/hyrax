module HydraHelper

  # collection of stylesheet links to be rendered in the <head>
  def stylesheet_links
    @stylesheet_links ||= []
  end
  
  # collection of javascript includes to be rendered in the <head>
  def javascript_includes
    @javascript_includes ||= []
  end
  
  def async_load_tag( url, tag )
    javascript_tag do 
      "window._token='#{form_authenticity_token}'" 
      "async_load('#{url}', '\##{tag}');"
    end
  end
  
  def link_to_multifacet( name, args={} )
    facet_params = {}
    options = {}
    args.each_pair do |k,v|
      if k == :options
        options = v
      else
        facet_params[:f] ||= {}
        facet_params[:f][k] ||= []
        v = v.instance_of?(Array) ? v.first : v
        facet_params[:f][k].push(v)
      end
    end

    link_to(name, catalog_index_path(facet_params), options)
  end
  
  def edit_and_browse_links
    result = ""
    if params[:action] == "edit"
      result << "<a href=\"#{catalog_path(@document[:id], :viewing_context=>"browse")}\" class=\"browse toggle\">Browse</a>"
      result << "<span class=\"edit toggle active\">Edit</span>"
    else
      result << "<span class=\"browse toggle active\">Browse</span>"
      result << "<a href=\"#{edit_catalog_path(@document[:id])}\" class=\"edit toggle\">Edit</a>"
    end
    # result << link_to "Browse", "#", :class=>"browse"
    # result << link_to "Edit", edit_document_path(@document[:id]), :class=>"edit"
    return result
  end
  
  def grouped_result_count(response, facet_name=nil, facet_value=nil)
    if facet_name && facet_value
      facet = response.facets.detect {|f| f.name == facet_name}
      facet_item = facet.items.detect {|i| i.value == facet_value} if facet
      count = facet_item ? facet_item.hits : 0
    else
      count = response.docs.total
    end
    pluralize(count, 'document')
  end
  
  def grouping_facet
    fields = Hash[sort_fields]
    case h(params[:sort])
    when fields['date -']
      'year_facet'
    when fields['date +']
      'year_facet'
    when fields['document type']
      'medium_t'
    when fields['location']
      'series_facet'
    else
      nil
    end
  end
  
  def document_fedora_show_html_title
    @document.datastreams["descMetadata"].title_values.first
  end
  
  # Returns the hits for facet_value within facet solr_fname within the solr_result.
  def facet_value_hits(solr_result, solr_fname, facet_value, default_response="1")
    item = solr_result.facets.detect {|f| f.name == solr_fname}.items.detect {|i| i.value == facet_value}
    if item
      return item.hits
    else
      return default_response
    end
  end
  
  def get_html_data_with_label(doc, label, field_string, opts={})
     if opts[:default] && !doc[field_string]
       doc[field_string] = opts[:default]
     end

     if doc[field_string]
       field = doc[field_string]
       text = "<dt>#{label}</dt><dd>"
       if field.is_a?(Array)
           field.each do |l|
             text += "#{CGI::unescapeHTML(l)}"
             if l != h(field.last)
               text += "<br/>"
             end
           end
       else
         text += CGI::unescapeHTML(field)
       end
       #Does the field have a vernacular equivalent? 
       if doc["vern_#{field_string}"]
         vern_field = doc["vern_#{field_string}"]
         text += "<br/>"
         if vern_field.is_a?(Array)
           vern_field.each do |l|
             text += "#{CGI::unescapeHTML(l)}"
             if l != h(vern_field.last)
               text += "<br/>"
             end
           end
         else
           text += CGI::unescapeHTML(vern_field)
         end
       end
       text += "</dd>"
       text
      end
   end
   
   def get_textile_data_with_label(doc, label, field_string, opts={})
      if opts[:default] && !doc[field_string]
        doc[field_string] = opts[:default]
      end

      if doc[field_string]
        field = doc[field_string]
        text = "<dt>#{label}</dt><dd>"
        if field.is_a?(Array)
            field.each do |l|
              text += "#{RedCloth.new(l).to_html}"
              if l != h(field.last)
                text += "<br/>"
              end
            end
        else
          text += RedCloth.new(field).to_html
        end
        text += "</dd>"
        text
       end
    end
  
  
  
end