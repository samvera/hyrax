module MetadataHelper
  
  def metadata_field(resource, datastream_name, field_key, opts={})
    if datastream_name.nil?
      raise ArgumentError.new("This method expects arguments of the form (resource, datastream_name, field_key, opts={})") 
    end
    # If user does not have edit permission, display non-editable metadata
    # If user has edit permission, display editable metadata
    editable_metadata_field(resource, datastream_name, field_key, opts)
  end
  
  # Convenience method for creating editable metadata fields.  Defaults to creating single-value field, but creates multi-value field if :multiple => true
  # Field name can be provided as a string or a symbol (ie. "title" or :title)
  def editable_metadata_field(resource, datastream_name, field_key, opts={})    
    field_name=field_key.to_s    
    result = ""
    
    case opts[:type]
    when :text_area
      result << text_area_inline_edit(resource, datastream_name, field_name, opts)
    when :date_picker
      result << date_picker_inline_edit(resource, datastream_name, field_name, opts)
    when :select
      result << metadata_drop_down(resource, datastream_name, field_name, opts)
    else
      if opts[:multiple] == true
        result << multi_value_inline_edit(resource, datastream_name, field_name, opts)
      else
        result << single_value_inline_edit(resource, datastream_name, field_name, opts)
      end
    end
    return result
  end
  

  def single_value_inline_edit(resource, datastream_name, field_name, opts={})
    resource_type = resource.class.to_s.underscore
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    result = "<dt for=\"#{resource_type}_#{field_name}\">#{label}</dt>"
    result << "<dd id=\"#{resource_type}_#{field_name}\"><ol id=\"#{resource_type}_#{field_name}_values\">"
    opts[:default] ||= ""
    field_value = get_values_from_datastream(resource, datastream_name, field_name, opts).first
    result << "<li class=\"editable\" id=\"#{resource_type}_#{field_name}_0\" name=\"#{resource_type}[#{field_name}][0]\"><span class=\"editableText\">#{h(field_value)}</span></li>"
    result << "</ol></dd>"
    
    return result
  end
  
  def multi_value_inline_edit(resource, datastream_name, field_name, opts={})
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    resource_type = resource.class.to_s.underscore
    result = ""
    result << "<dt for=\"#{resource_type}_#{field_name}\">#{label}"
    result << "<a class='addval' data-field_name='#{field_name}' href='#'>+</a>"
    result << "</dt>"
    result << "<dd id=\"#{resource_type}_#{field_name}\"><ol id=\"#{resource_type}_#{field_name}_values\">"
    
    opts[:default] = "" unless opts[:defualt]
    oid = resource.pid
    new_element_id = "#{resource_type}_#{field_name}_-1"
    rel = url_for(:action=>"update", :controller=>"assets")
    
    #opts[:default] ||= ""
    #Output all of the current field values.
    datastream = resource.datastreams[datastream_name]
    vlist = get_values_from_datastream(resource, datastream_name, field_name, opts)
    vlist.each_with_index do |field_value,z|
      result << "<li class=\"editable\" id=\"#{resource_type}_#{field_name}_#{z}\" name=\"#{resource_type}[#{field_name}][#{z}]\">"
      result << "<a href='#' class='destructive'><img src='/images/delete.png' border='0' /></a>" unless z == 0
      result << "<span class=\"editableText\">#{h(field_value)}</span>"
      result << "</li>"
    end
    # result << "<div id=\"#{resource_type}_#{field_name}_new_values\"></div>"
    result << "</ol></dd>"
    
    return result
  end

  def text_area_inline_edit(resource, datastream_name, field_name, opts={})
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    resource_type = resource.class.to_s.underscore
    opts[:default] = ""
    result = ""
    result << "<dt for=\"#{resource_type}_#{field_name}\">#{label}"
    result << link_to_function("+" , "insertTextAreaValue(\"#{field_name}\")", :class=>'addval') 
    result << "</dt>"   
    
    result << "<dd id=\"#{resource_type}_#{field_name}\"><ol id=\"#{resource_type}_#{field_name}_values\">"
    
    vlist = get_values_from_datastream(resource, datastream_name, field_name, opts)
    vlist.each_with_index do |field_value,z|
      result << "<li id=\"#{resource_type}_#{field_name}_#{z}\" name=\"#{resource_type}[#{field_name}][#{z}]\"  class=\"editable_textarea\">"
      result << link_to_function(image_tag("delete.png") , "removeFieldValue(this)", :class=>'destructive') unless z == 0
      result << "<div class=\"flc-inlineEdit-text\">#{field_value}</div>"
      result << "<div class=\"flc-inlineEdit-editContainer\">"
      result << "      <textarea></textarea>"
      result << "      <button class=\"save\">Save</button> <button class=\"cancel\">Cancel</button>"
      result << "</div>"
      result << "</li>"
    end
    # result << "<div id=\"#{resource_type}_#{field_name}_new_values\"></div>"
    result << "</ol></dd>"
    
    return result
  end
  
  # Returns an HTML select with options populated from opts[:choices].
  # If opts[:choices] is not provided, or if it's not a Hash, a single_value_inline_edit will be returned instead.
  # Will capitalize the key for each choice when displaying it in the options list.  The value is left alone.
  def metadata_drop_down(resource, datastream_name, field_name, opts={})
    if opts[:choices].nil? || !opts[:choices].kind_of?(Hash)
      single_value_inline_edit(resource, datastream_name, field_name, opts)
    else
      if opts.has_key?(:label) 
        label = opts[:label]
      else
        label = field_name
      end
      resource_type = resource.class.to_s.underscore
      opts[:default] ||= ""
      
      result = "<dt for=\"#{resource_type}_#{field_name}\">#{label}</dt>"
      
      choices = opts[:choices]
      field_value = get_values_from_datastream(resource, datastream_name, field_name, opts).first
      choices.delete_if {|k, v| v == field_value || v == field_value.capitalize }
      result << "<dd id=\"#{resource_type}_#{field_name}\">"
      result << "<select name=\"#{resource_type}[#{field_name}][0]\" onchange=\"saveSelect(this)\"><option value=\"#{field_value}\" selected=\"selected\">#{h(field_value.capitalize)}</option>"
      choices.each_pair do |k,v|
        result << "<option value=\"#{v}\">#{h(k)}</option>"
      end
      result << "</select>"
      result << "</dd>"
      return result
    end
  end
  
  def date_picker_inline_edit(resource, datastream_name, field_name, opts={})
    resource_type = resource.class.to_s.underscore
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    
    z = "0" # single-values only 
    
    result = "<dt for=\"#{resource_type}_#{field_name}\">#{label}</dt>"
    result << "<dd id=\"#{resource_type}_#{field_name}\"><ol id=\"#{resource_type}_#{field_name}_values\">"
    opts[:default] ||= ""
    field_value = get_values_from_datastream(resource, datastream_name, field_name, opts).first
    # result << "<li class=\"date_picker\" id=\"#{resource_type}_#{field_name}\" name=\"#{resource_type}[#{field_name}][0]\"><span class=\"editableText\">#{field_value}</span></li>"
    result << "<li id=\"#{resource_type}_#{field_name}_#{z}\" name=\"#{resource_type}[#{field_name}][#{z}]\"  class=\"editable_date_picker\">"
    # result << link_to_remote(image_tag("delete.png"), :update => "", :url => {:action=>:show, "#{resource_type}[#{field_name}][#{z}]"=>""}, :method => :put, :success => visual_effect(:fade, "#{field_name}_#{z}"),:html => { :class  => "destructive" })
    result << "<div class=\"flc-inlineEdit-text editableText\">#{field_value}</div>"
    result << "<div class=\"flc-inlineEdit-editContainer\">"
    result << "      <input type=\"text\" readonly=\"readonly\" class=\"date_picker w16em flc-inlineEdit-edit\" id=\"#{resource_type}_#{field_name}_#{z}_value_input\" value=\"#{field_value}\"></input>"
    result << "</div>"
    result << "</li>"
    #result << "<input type=\"text\" class=\"date_picker w16em\" id=\"#{resource_type}_#{field_name}_value\" name=\"#{resource_type}[#{field_name}][0]\" value=\"#{field_value}\"></input>"
    result << "</ol></dd>"
    
    return result
  end
  
  def get_values_from_datastream(resource, datastream_name, field_name, opts={})
    result = resource.datastreams[datastream_name].send("#{field_name}_values")
    if result.empty? && opts[:default]
      result = [opts[:default]]
    end
    return result
  end
  
  def custom_dom_id(resource)
    classname = resource.class.to_s.gsub(/[A-Z]+/,'\1_\0').downcase[1..-1]
    url = "#{classname}_#{resource.pid}"   
  end
  
end
