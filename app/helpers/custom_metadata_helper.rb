module CustomMetadataHelper
  
  include WhiteListHelper
  
  def custom_metadata_field(resource, datastream_name, field_key, opts={})
    if datastream_name.nil?
      raise ArgumentError.new("This method expects arguments of the form (resource, datastream_name, field_key, opts={})") 
    end
    # If user does not have edit permission, display non-editable metadata
    # If user has edit permission, display editable metadata
    editable_metadata_field(resource, datastream_name, field_key, opts)
  end
  
  # Convenience method for creating editable metadata fields.  Defaults to creating single-value field, but creates multi-value field if :multiple => true
  # Field name can be provided as a string or a symbol (ie. "title" or :title)
  def custom_editable_metadata_field(resource, datastream_name, field_key, opts={})    
        
    
    
    case opts[:type]
    when :text_area
      result = custom_editable_textile(resource, datastream_name, field_key, opts)
    when :editable_textile
      result = custom_editable_textile(resource, datastream_name, field_key, opts)
    when :date_picker
      result = custom_date_select(resource, datastream_name, field_key, opts)

    when :select
      result = custom_metadata_drop_down(resource, datastream_name, field_key, opts)
    else
      if opts[:multiple] == true
        result = custom_multi_value_inline_edit(resource, datastream_name, field_key, opts)
      else
        result = custom_single_value_inline_edit(resource, datastream_name, field_key, opts)
      end
    end
    return result
  end
  
  
  def custom_single_value_inline_edit(resource, datastream_name, field_key, opts={})
    resource_type = resource.class.to_s.underscore
    
    field_params = field_update_params(resource, datastream_name, field_key, opts)
    field_name = field_params[:field_name]
    
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    
    opts[:default] ||= ""
    field_value = get_values_from_datastream(resource, datastream_name, field_key, opts).first
    result = "<ol>"
      if field_params.has_key?("parent_select")
        name = field_params.merge({"child_index"=>0}).to_query + "&value"
        # result << "<li class=\"editable\" name=\"datastream=#{datastream_name}#{xml_update_params}&child_index=0&value\">"
      else
        name = field_params.to_query + "&asset[#{field_name}][0]"
        # result << "<li class=\"editable\" name=\"asset[#{field_name}][0]\">"
      end
      result << "<li class=\"editable\" name=\"#{name}\">"
        result <<"<span class=\"editableText\">#{h(field_value)}</span>"
      result << "</li>"
    result << "</ol>"
    
    return :label=>label, :field=> result
  end
  
  def custom_multi_value_inline_edit(resource, datastream_name, field_key, opts={})
    field_name=field_key.to_s
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name.dup
    end
    label << "<a class='addval input' href='#'>+</a>"
    resource_type = resource.class.to_s.underscore
    opts[:default] = "" unless opts[:default]
    result = ""
    result << "<ol>"
      #Output all of the current field values.
      datastream = resource.datastreams[datastream_name]
      vlist = get_values_from_datastream(resource, datastream_name, field_key, opts)
      vlist.each_with_index do |field_value,z|
        result << "<li class=\"editable\" name=\"asset[#{field_name}][#{z}]\">"
          result << "<a href='' title='Delete \'#{h(field_value)}\'' class='destructive'><img src='/plugin_assets/hydra_repository/images/delete.png' alt='Delete'></a>" unless z == 0
        result << "<span class=\"editableText\">#{h(field_value)}</span>"
      result << "</li>"
    end
    result << "</ol>"
    
    return :label=>label, :field => result
  end
  
  def custom_editable_textile(resource, datastream_name, field_key, opts={})
    field_name=field_key.to_s
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name.dup
    end
    label << "<a class='addval textArea' href='#'>+</a>"
    escaped_field_name=field_name.gsub(/_/, '+')
    resource_type = resource.class.to_s.underscore
    escaped_resource_type = resource_type.gsub(/_/, '+')
    
    opts[:default] = ""
    result = ""
    result << "<ol>"
      vlist = get_values_from_datastream(resource, datastream_name, field_key, opts)
      vlist.each_with_index do |field_value,z|
        processed_field_value = white_list( RedCloth.new(field_value, [:sanitize_html]).to_html)
          field_id = "#{field_name}_#{z}"
          result << "<li name=\"asset[#{field_name}][#{z}]\"  class=\"field_value textile_value\">"
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
  def custom_metadata_drop_down(resource, datastream_name, field_key, opts={})
    field_name=field_key.to_s
    if opts[:choices].nil? || !opts[:choices].kind_of?(Hash)
      single_value_inline_edit(resource, datastream_name, field_key, opts)
    else
      if opts.has_key?(:label) 
        label = opts[:label]
      else
        label = field_name
      end
      resource_type = resource.class.to_s.underscore
      opts[:default] ||= ""
      
      result = ""      
      choices = opts[:choices]
      field_value = get_values_from_datastream(resource, datastream_name, field_key, opts).first
      choices.delete_if {|k, v| v == field_value || v == field_value.capitalize }

      result << "<select name=\"asset[#{field_name}][0]\" class=\"metadata-dd\"><option value=\"#{field_value}\" selected=\"selected\">#{h(field_value.capitalize)}</option>"
        choices.each_pair do |k,v|
          result << "<option value=\"#{v}\">#{h(k)}</option>"
        end
      result << "</select>"
      return :label=>label, :field=>result
    end
  end
  
  def custom_date_select(resource, datastream_name, field_key, opts={})
    field_name=field_key.to_s
    resource_type = resource.class.to_s.underscore
    if opts.has_key?(:label) 
      label = opts[:label]
    else
      label = field_name
    end
    
    z = "0" # single-values only 
    
    result = ""
    opts[:default] ||= ""
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

    result << "<div class=\"date-select\" name=\"asset[#{field_name}][#{z}]\">"
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
  
  # def field_update_params(resource, datastream_name, field_key, opts={})
  #   url_params = {"datastream"=>datastream_name}
  #   field_name = field_key.to_s
  #   url_params[:field_name] = field_name
  #   
  #   if field_key.kind_of?(Array)
  #     url_params["parent_select"] = field_key
  #     # field_key.each do |x|
  #     #   if x.kind_of?(Hash)
  #     #     url_params << "&parent_select[][#{x.keys.first.inspect}]=#{x.values.first.inspect}"          
  #     #   else
  #     #     url_params << "&parent_select[]=#{x.inspect}"
  #     #   end
  #     # end
  #   end
  #     #{"asset"=>{"fieldName"=>{1=>nil}}}
  # 
  #   return url_params
  # end
  
end
