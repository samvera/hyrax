require "hydra_helper"
module ApplicationHelper
  include Stanford::SearchworksHelper
  #include Stanford::SolrHelper # this is already included by the SearchworksHelper
  include HydraHelper
  
  def application_name
    'A Hydra Head'
  end
  
  def get_data_with_linked_label(doc, label, field_string, opts={})
   
    (opts[:default] and !doc[field_string]) ? field = opts[:default] : field = doc[field_string]
    delim = opts[:delimiter] ? opts[:delimiter] : "<br/>"
    if doc[field_string]
      text = "<dt>#{label}</dt><dd>"
      if field.respond_to?(:each)
        text += field.map do |l| 
          linked_label(l, field_string)
        end.join(delim)
      else
        text += linked_label(field, field_string)
      end
      text += "</dd>"
      text
    end
  end
  
  def linked_label(field, field_string)
    link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
  end
  def link_to_document(doc, opts={:label=>Blacklight.config[:index][:show_link].to_sym, :counter => nil,:title => nil})
    label = case opts[:label]
      when Symbol
        doc.get(opts[:label])
      when String
        opts[:label]
      else
        raise 'Invalid label argument'
      end

    if label.blank?
      label = doc[:id]
    end
    
    link_to_with_data(label, catalog_path(doc[:id]), {:method => :put, :data => {:counter => opts[:counter]},:title=>opts[:title]})
  end

  # currently only used by the render_document_partial helper method (below)
  def document_partial_name(document)
    if !document[Blacklight.config[:show][:display_type]].nil?
      return document[Blacklight.config[:show][:display_type]].first.gsub("info:fedora/afmodel:","").underscore.pluralize
    else
      return nil
    end
  end
  
  # Overriding Blacklight's render_document_partial
  # given a doc and action_name, this method attempts to render a partial template
  # based on the value of doc[:format]
  # if this value is blank (nil/empty) the "default" is used
  # if the partial is not found, the "default" partial is rendered instead
  def render_document_partial(doc, action_name, locals={})
    format = document_partial_name(doc)
    begin
      Rails.logger.debug("attempting to render #{format}/_#{action_name}")
      render :partial=>"#{format}/#{action_name}", :locals=>{:document=>doc}.merge(locals)
    rescue ActionView::MissingTemplate
      Rails.logger.debug("rendering default partial catalog/_#{action_name}_partials/default")
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>{:document=>doc}.merge(locals)
    end
  end
  
  ###
  ### Overrides pulled in from Libra
  ###
  
  def render_facet_value(facet_solr_field, item, options ={})
    if item.is_a? Array
      link_to_unless(options[:suppress_link], item[0], add_facet_params_and_redirect(facet_solr_field, item[0]), :class=>"facet_select") + " (" + format_num(item[1]) + ")" 
    else
      link_to_unless(options[:suppress_link], item.value, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
    end
  end

  # Removing the [remove] link from the default selected facet display
  def render_selected_facet_value(facet_solr_field, item)
    '<span class="selected">' +
    render_facet_value(facet_solr_field, item, :suppress_link => true) +
    '</span>'
  end

  def render_complex_facet_value(facet_solr_field, item, options ={})    
    link_to_unless(options[:suppress_link], format_item_value(item.value), add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
  end

  def render_journal_facet_value(facet_solr_field, item, options ={})

    val = item.value.strip.length > 12 ? item.value.strip[0..12].concat("...") : item.value.strip
    link_to_unless(options[:suppress_link], val, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
  end

  def render_complex_facet_image(facet_solr_field, item, options = {})
    computing_id = extract_computing_id(item.value)
    if File.exists?("#{Rails.root}/public/images/faculty_images/#{computing_id}.jpg")
      img = image_tag "/images/faculty_images/#{computing_id}.jpg", :width=> "100", :alt=>"#{item.value}"
    else
      img = image_tag "/plugin_assets/hydra-head/images/default_thumbnail.gif", :width=>"100", :alt=>"#{item.value}"
    end
    link_to_unless(options[:suppress_link], img, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select facet_image") 
  end

  def render_journal_image(facet_solr_field, item, options = {})
    if File.exists?("#{Rails.root}/public/images/journal_images/#{item.value.strip.downcase.gsub(/\s+/,'_')}.jpg")
      img = image_tag "/images/journal_images/#{item.value.strip.downcase.gsub(/\s+/,'_')}.jpg", :width => "100"
    else
      img = image_tag "/plugin_assets/hydra-head/images/default_thumbnail.gif", :width=>"100", :alt=>"#{item.value}"
    end

    link_to_unless(options[:suppress_link], img, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") 
  end

  def get_randomized_display_items items
    clean_items = items.each.inject([]) do |array, item|
      array << item unless item.value.strip.blank?
      array
    end

    if clean_items.length < 6 
      clean_items.sort_by {|item| item.value }
    else 
      rdi = clean_items.sort_by {rand}.slice(0..5)
      return rdi.sort_by {|item| item.value.downcase}
    end

  end

  def extract_computing_id val
    cid = val.split(" ")[-1]
    cid[1..cid.length-2]
  end

  def format_item_value val
    begin
      last, f_c = val.split(", ")
      first = f_c.split(" (")[0]
    rescue
      return val.nil? ? "" : val
    end
    [last, "#{first[0..0]}."].join(", ")
  end

#   COPIED from vendor/plugins/blacklight/app/helpers/application_helper.rb
  # Used in catalog/facet action, facets.rb view, for a click
  # on a facet value. Add on the facet params to existing
  # search constraints. Remove any paginator-specific request
  # params, or other request params that should be removed
  # for a 'fresh' display. 
  # Change the action to 'index' to send them back to
  # catalog/index with their new facet choice. 
  def add_facet_params_and_redirect(field, value)
    new_params = add_facet_params(field, value)

    # Delete page, if needed. 
    new_params.delete(:page)

    # Delete :qt, if needed - added to resolve NPE errors
    new_params.delete(:qt)

    # Delete any request params from facet-specific action, needed
    # to redir to index action properly. 
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key| 
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index. 
    new_params[:action] = "index"

    new_params
  end

end
