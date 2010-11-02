require 'mediashelf/active_fedora_helper'

module ApplicationHelper
  include MediaShelf::ActiveFedoraHelper
  include Stanford::SearchworksHelper
  #include Stanford::SolrHelper # this is already included by the SearchworksHelper
  include HydraHelper
  
  def application_name
    'Hydrangea (Hydra Demo App)'
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

end
