module MetadataHelper
  
  include WhiteListHelper
  
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
    case opts[:type]
    when :text_area
      result = editable_textile(resource, datastream_name, field_key, opts)
    when :editable_textile
      result = editable_textile(resource, datastream_name, field_key, opts)
    when :date_picker
      result = date_select(resource, datastream_name, field_key, opts)

    when :select
      result = metadata_drop_down(resource, datastream_name, field_key, opts)
    else
      if opts[:multiple] == true
        result = multi_value_inline_edit(resource, datastream_name, field_key, opts)
      else
        result = single_value_inline_edit(resource, datastream_name, field_key, opts)
      end
    end
    return result
  end
  
  
  def single_value_inline_edit(resource, datastream_name, field_key, opts={})    
    field_params = field_update_params(resource, datastream_name, field_key, opts)
    field_name = field_params.delete(:field_name)
    
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    
    field_value = get_values_from_datastream(resource, datastream_name, field_key, opts).first
    result = "<ol>"
      z = "0"
      name = add_param(field_params.to_query,"asset[#{datastream_name}][#{field_name}][#{z}]")
      result << "<li class=\"editable\" name=\"#{name}\">"
        result <<"<span class=\"editableText\">#{h(field_value)}</span>"
      result << "</li>"
    result << "</ol>"
    
    return :label=>label, :field=> result
  end
  
  def multi_value_inline_edit(resource, datastream_name, field_key, opts={})    
    field_params = field_update_params(resource, datastream_name, field_key, opts)
    field_name = field_params.delete(:field_name)
    
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name.dup
    end
    label << "<a class='addval input' href='#'>+</a>"
    opts[:default] = "" unless opts[:default]
    result = ""
    result << "<ol>"
      #Output all of the current field values.
      datastream = resource.datastreams[datastream_name]
      vlist = get_values_from_datastream(resource, datastream_name, field_key, opts)
      vlist.each_with_index do |field_value,z|
        name = add_param(field_params.to_query,"asset[#{datastream_name}][#{field_name}][#{z}]")
        result << "<li class=\"editable\" name=\"#{name}\">"
          result << "<a href='' title='Delete \'#{h(field_value)}\' class='destructive'><img src='/plugin_assets/hydra_repository/images/delete.png' alt='Delete'></a>" unless z == 0
        result << "<span class=\"editableText\">#{h(field_value)}</span>"
      result << "</li>"
    end
    result << "</ol>"
    
    return :label=>label, :field => result
  end
  
  def editable_textile(resource, datastream_name, field_key, opts={})    
    field_params = field_update_params(resource, datastream_name, field_key, opts)
    field_name = field_params.delete(:field_name)
    
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name.dup
    end
    if opts[:multiple]
      label << "<a class='addval textArea' href='#'>Add #{field_name}</a>"
    end
    escaped_field_name=field_name.gsub(/_/, '+')
    
    opts[:default] = ""
    result = ""
    result << "<ol>"
      vlist = get_values_from_datastream(resource, datastream_name, field_key, opts)
      vlist.each_with_index do |field_value,z|
        name = add_param(field_params.to_query,"asset[#{datastream_name}][#{field_name}][#{z}]")
        processed_field_value = white_list( RedCloth.new(field_value, [:sanitize_html]).to_html)
          field_id = "#{field_name}_#{z}"
          result << "<li name=\"#{name}\"  class=\"field_value textile_value\">"
            # Not sure why there is we're not allowing the for the first textile to be deleted, but this was in the original helper.
            result << "<a href='' title='Delete \'#{processed_field_value}\'' class='destructive'><img src='/plugin_assets/hydra_repository/images/delete.png' alt='Delete'></a>" unless z == 0
            result << "<div class=\"textile\" id=\"#{field_id}\">#{processed_field_value}</div>"
          result << "</li>"
    end
    result << "</ol>"
    
    return :label=>label, :field=>result
  end
  
  # Returns an HTML select with options populated from opts[:choices].
  # If opts[:choices] is not provided, or if it's not a Hash, a single_value_inline_edit will be returned instead.
  # Will capitalize the key for each choice when displaying it in the options list.  The value is left alone.
  def metadata_drop_down(resource, datastream_name, field_key, opts={})    
    field_params = field_update_params(resource, datastream_name, field_key, opts)
    field_name = field_params.delete(:field_name)

    if opts[:choices].nil? || !opts[:choices].kind_of?(Hash)
      single_value_inline_edit(resource, datastream_name, field_key, opts)
    else
      if opts.has_key?(:label) 
        label = opts[:label]
      else
        label = field_name
      end      
      
      result = ""      
      choices = opts[:choices]
      field_value = get_values_from_datastream(resource, datastream_name, field_key, opts).first
      z = "0"
      name = add_param(field_params.to_query,"asset[#{datastream_name}][#{field_name}][#{z}]")
      
      if field_value.nil?
        result << "<select name=\"#{name}\" class=\"metadata-dd\">"
      else
        choices.delete_if {|k, v| v == field_value || v == field_value.capitalize }
        result << "<select name=\"#{name}\" class=\"metadata-dd\"><option value=\"#{field_value}\" selected=\"selected\">#{h(field_value.capitalize)}</option>"
      end
        choices.each_pair do |k,v|
          result << "<option value=\"#{v}\">#{h(k)}</option>"
        end
      result << "</select>"
      return :label=>label, :field=>result
    end
  end
  
  def date_select(resource, datastream_name, field_key, opts={})
    field_params = field_update_params(resource, datastream_name, field_key, opts)
    field_name = field_params.delete(:field_name)
    
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    
    z = "0" # single-values only 
    
    result = ""
    
    value = get_values_from_datastream(resource, datastream_name, field_key, opts).first
    field_value = value.nil? ? "" : value
        
    field_value[/(\d+)-(\d+)-(\d+)/]
    year = ($1.nil? or $1.empty?) ? "" : $1.to_i
    month = ($2.nil? or $2.empty?) ? "-1" : $2
    day = ($3.nil? or $3.empty?) ? "-1" : $3
    
    # Make sure that month and day values are double-digit
    [month, day].each {|v| v.length == 1 ? v.insert(0, "0") : nil }
    
    
    year_options = Array.new(101) {|i| 1910+i}
    # year_options = Array.new(4) {|i| 1990+i}
    
    year_options.insert(0, ["Year", "-1"])
    name = add_param(field_params.to_query,"asset[#{datastream_name}][#{field_name}][#{z}]")
    result << "<div class=\"date-select\" name=\"#{name}\">"
      result << "<input class=\"controlled-date-part w4em\" style=\"width:4em;\" type=\"text\" id=\"#{field_name}_#{z}-sel-y\" name=\"#{field_name}_#{z}-sel-y\" maxlength=\"4\" value=\"#{year}\" />"    
      result << "<select class=\"controlled-date-part\" id=\"#{field_name}_#{z}-sel-mm\" name=\"#{field_name}_#{z}-sel-mm\">"
        result << options_for_select([["Month","-1"],["January", "01"],["February", "02"],["March", "03"],
                                      ["April", "04"],["May", "05"],["June", "06"],["July", "07"],["August", "08"],
                                      ["September", "09"],["October", "10"],["November", "11"],["December", "12"]
                                      ], month)
      result << "</select> / "
      result << "<select class=\"controlled-date-part\" id=\"#{field_name}_#{z}-sel-dd\" name=\"#{field_name}_#{z}-sel-dd\">"
        result << options_for_select([["Day","-1"],"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"], day)
      result << "</select>"
    result << "</div>"
    result << <<-EOF
    <script type="text/javascript">
    // <![CDATA[  
      // since the form element ids need to be generated on the server side for the options, the options are attached to the wrapping div via the jQuery data() method.
      $('div.date-select[name="asset[#{field_name}][#{z}]"]').data("opts", {                            
        formElements:{"#{field_name}_#{z}-sel-dd":"d","#{field_name}_#{z}-sel-y":"Y","#{field_name}_#{z}-sel-mm":"m"}         
      });          
    // ]]>
    </script>
    EOF
    return :label=>label, :field=>result
  end
  
  def field_update_params(resource, datastream_name, field_key, opts={})
    
    url_params = {}
    # url_params = {"datastream"=>datastream_name}
    if resource.kind_of?(String)
      ds = ActiveFedora::NokogiriDatastream.new
    else
      ds = resource.datastreams_in_memory[datastream_name]
    end
    
    if ds.kind_of?(ActiveFedora::NokogiriDatastream)
      field_name = OM::XML::Terminology.term_hierarchical_name(*field_key)
      url_params[:field_name] = field_name
      url_params["field_selectors"] = {datastream_name=>{field_name => field_key} }
    else
      field_name = field_key.to_s
      url_params[:field_name] = field_name
    end
    # url_params["asset"][datastream_name] = {field_name => }
    return url_params
  end
  
  def get_values_from_datastream(resource, datastream_name, field_key, opts={})
    if opts.has_key?(:values)
      values = opts[:values]
      if values.nil? then values = [opts.fetch(:default, "")] end
      return values
    else
      return resource.get_values_from_datastream(datastream_name, field_key, opts.fetch(:default, ""))
    end
  end
  
  def add_param(query_string, new_param)
    if query_string.empty?
      return new_param
    else
      return query_string + "&" + new_param
    end
  end
  
  def custom_dom_id(resource)
    classname = resource.class.to_s.gsub(/[A-Z]+/,'\1_\0').downcase[1..-1]
    url = "#{classname}_#{resource.pid}"   
  end
  
  def prefab_editable_metadata_field(resource, datastream_name, field_key, opts={})
    field_name = field_key.to_s
    result = ""
    generated_stuff = editable_metadata_field(@document_fedora, "rightsMetadata", :discover_access_group, :label => "Discover Access:", :type=>:select, :choices=>{"Public" => "public","Researchers" => "researcher", "Archivists" => "archivist", "Archivists" => "archivist"})      
    result << "<dt>"
    result << "<label for=\'#{field_name}\">"
    result << generated_stuff[:label]
    result << "</dt>"
    
    result << "<dd id=\"#{field_name}\">"
    result << generated_stuff[:field]
    result << "</dd>"
  end
  
end
