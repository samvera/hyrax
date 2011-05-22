require "inline_editable_metadata_helper"
require "block_helpers"
require "active_support"
require "redcloth" # Provides textile parsing support for textile_area method

module HydraFedoraMetadataHelper
  
  def fedora_text_field(resource, datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    field_values = [""] if field_values.empty?
    if opts.fetch(:multiple, true)
      container_tag_type = :li
    else
      field_values = [field_values.first]
      container_tag_type = :span
    end
    
    body = ""
    
    field_values.each_with_index do |current_value, z|
      base_id = generate_base_id(field_name, current_value, field_values, opts)
      name = "asset[#{datastream_name}][#{field_name}][#{z}]"
      body << "<#{container_tag_type.to_s} class=\"editable-container field\" id=\"#{base_id}-container\">"
        body << "<a href=\"\" title=\"Delete '#{h(current_value)}'\" class=\"destructive field\">Delete</a>" if opts.fetch(:multiple, true) && !current_value.empty?
        body << "<span class=\"editable-text text\" id=\"#{base_id}-text\" style=\"display:none;\">#{h(current_value.lstrip)}</span>"
        body << "<input class=\"editable-edit edit\" id=\"#{base_id}\" data-datastream-name=\"#{datastream_name}\" rel=\"#{field_name}\" name=\"#{name}\" value=\"#{h(current_value.lstrip)}\"/>"
      body << "</#{container_tag_type}>"
    end
    result = field_selectors_for(datastream_name, field_key)
    if opts.fetch(:multiple, true)
      result << content_tag(:ol, body, :rel=>field_name)
    else
      result << body
    end
    
    return result
  end
  
  def fedora_text_area(resource, datastream_name, field_key, opts={})
    fedora_textile_text_area(resource, datastream_name, field_key, opts)
  end
  
  # Textile textarea varies from the other methods in a few ways
  # Since we're using jeditable with this instead of fluid, we need to provide slightly different hooks for the javascript
  # * we are storing the datastream name in data-datastream-name so that we can construct a load url on the fly when initializing the textarea
  def fedora_textile_text_area(resource, datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    field_values = [""] if field_values.empty?
    if opts.fetch(:multiple, true)
      container_tag_type = :li
    else
      field_values = [field_values.first]
      container_tag_type = :span
    end
    body = ""
    
    field_values.each_with_index do |current_value, z|
      base_id = generate_base_id(field_name, current_value, field_values, opts)
      name = "asset[#{datastream_name}][#{field_name}][#{z}]"
      processed_field_value = white_list( RedCloth.new(current_value, [:sanitize_html]).to_html)
      
      body << "<#{container_tag_type.to_s} class=\"editable-container field\" id=\"#{base_id}-container\">"
        # Not sure why there is we're not allowing the for the first textile to be deleted, but this was in the original helper.
        body << "<a href=\"\" title=\"Delete '#{h(current_value)}'\" class=\"destructive field\">Delete</a>" unless z == 0
        body << "<span class=\"editable-text text\" id=\"#{base_id}-text\" style=\"display:none;\">#{processed_field_value}</span>"
        body << "<textarea class=\"editable-edit edit\" id=\"#{base_id}\" data-datastream-name=\"#{datastream_name}\" rel=\"#{field_name}\" name=\"#{name}\" rows=\"10\" cols=\"25\">#{h(current_value)}</textarea>"
        #body << "<input class=\"editable-edit edit\" id=\"#{base_id}\" data-datastream-name=\"#{datastream_name}\" rel=\"#{field_name}\" name=\"#{name}\" value=\"#{h(current_value)}\"/>"
      body << "</#{container_tag_type}>"
    end
    
    result = field_selectors_for(datastream_name, field_key)
    
    if opts.fetch(:multiple, true)
      result << content_tag(:ol, body, :rel=>field_name)
    else
      result << body
    end
    return result
    
  end
  
  # Expects :choices option.  Option tags for the select are generated from the :choices option using Rails "options_for_select":http://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/options_for_select helper
  # If no :choices option is provided, returns a regular fedora_text_field
  def fedora_select(resource, datastream_name, field_key, opts={})
    if opts[:choices].nil?
      result = fedora_text_field(resource, datastream_name, field_key, opts)
    else
      choices = opts[:choices]
      field_name = field_name_for(field_key)
      field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
      
      body = ""
      z = 0
      base_id = generate_base_id(field_name, field_values.first, field_values, opts.merge({:multiple=>false}))
      name = "asset[#{datastream_name}][#{field_name}][#{z}]"

      body << "<select name=\"#{name}\" class=\"metadata-dd select-edit\" id=\"#{field_name}\" rel=\"#{field_name}\">"
        body << options_for_select(choices, field_values)
      body << "</select>"
      
      result = field_selectors_for(datastream_name, field_key)
      result << body
    end
    return result
  end
  
  def fedora_date_select(resource, datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    base_id = generate_base_id(field_name, field_values.first, field_values, opts.merge({:multiple=>false}))
    name = "asset[#{datastream_name}][#{base_id}]"
    
    value = field_values.first
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
    
    body = ""
    body << "<div class=\"date-select\" name=\"#{name}\" rel=\"#{field_name}\">"
      body << "<input class=\"controlled-date-part w4em\" style=\"width:4em;\" type=\"text\" id=\"#{base_id}-sel-y\" name=\"#{base_id}-sel-y\" maxlength=\"4\" value=\"#{year}\" />"    
      body << "<select class=\"controlled-date-part\" id=\"#{base_id}-sel-mm\" name=\"#{base_id}-sel-mm\">"
        body << options_for_select([["Month","-1"],["January", "01"],["February", "02"],["March", "03"],
                                      ["April", "04"],["May", "05"],["June", "06"],["July", "07"],["August", "08"],
                                      ["September", "09"],["October", "10"],["November", "11"],["December", "12"]
                                      ], month)
      body << "</select> / "
      body << "<select class=\"controlled-date-part\" id=\"#{base_id}-sel-dd\" name=\"#{base_id}-sel-dd\">"
        body << options_for_select([["Day","-1"],"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"], day)
      body << "</select>"
    body << "</div>"
    body << <<-EOF
    <script type="text/javascript">
    // <![CDATA[  
      // since the form element ids need to be generated on the server side for the options, the options are attached to the wrapping div via the jQuery data() method.
      $('div.date-select[name="#{name}"]').data("opts", {                            
        formElements:{"#{base_id}-sel-dd":"d","#{base_id}-sel-y":"Y","#{base_id}-sel-mm":"m"}         
      });          
    // ]]>
    </script>
    EOF
    
    result = field_selectors_for(datastream_name, field_key)
    result << body
    return result
  end

  def fedora_submit(resource, datastream_name, field_key, opts={})
    result = ""
    h_name = OM::XML::Terminology.term_hierarchical_name(*field_key)    
    field_key.each do |pointer|
      result << tag(:input, :type=>"submit", :rel=>h_name, :name=>"field_selectors[#{datastream_name}][#{h_name}]", :value => field_key.to_s.capitalize)
    end
    return result
  end
  
  def fedora_checkbox(resource, datastream_name, field_key, opts={})
    result = ""
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    h_name = OM::XML::Terminology.term_hierarchical_name(*field_key)    
    
    v_name = field_key.last.to_s

    checked = field_values.first.downcase == "yes" ? "checked" : ""
    
    result = field_selectors_for(datastream_name, field_key)
    
    # adding so that customized checked and unchecked values can be passed in
    checked_value = (opts[:default_values] && opts[:default_values][:checked]) ? opts[:default_values][:checked] : "yes"
    unchecked_value = (opts[:default_values] && opts[:default_values][:unchecked]) ? opts[:default_values][:unchecked] : "no"

    result << tag(:input, :type=>"hidden", :id=>"#{h_name}_checked_value", :value=>checked_value )
    result << tag(:input, :type=>"hidden", :id=>"#{h_name}_unchecked_value", :value=>unchecked_value )
    
    if field_values.first.downcase == "yes"
      result << tag(:input, :type=>"checkbox", :id=>h_name, :class=>"fedora-checkbox", :rel=>h_name, :name=>"asset[#{datastream_name}][#{h_name}][0]", :value=>checked_value, :checked=>"checked")
    else
      result << tag(:input, :type=>"checkbox", :id=>h_name, :class=>"fedora-checkbox", :rel=>h_name, :name=>"asset[#{datastream_name}][#{h_name}][0]", :value=>unchecked_value)
    end
    return result
  end
  
  # Expects :choices option. 
  # :choices should be a hash with value/label pairs
  # :choices => {"first_choice"=>"Apple", "second_choice"=>"Pear" }
  # If no :choices option is provided, returns a regular fedora_text_field
  def fedora_radio_button(resource, datastream_name, field_key, opts={})
    if opts[:choices].nil?
      result = fedora_text_field(resource, datastream_name, field_key, opts)
    else
      choices = opts[:choices]
      
      field_name = field_name_for(field_key)
      field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
      h_name = OM::XML::Terminology.term_hierarchical_name(*field_key)    
      default_value = opts.keys.include?(:default_value) ? opts[:default_value] : ""
      
      selected_value = field_values.empty? ? "" : field_values.first
      selected_value = default_value if selected_value.blank?

      body = ""
      z = 0
      base_id = generate_base_id(field_name, field_values.first, field_values, opts.merge({:multiple=>false}))
      name = "asset[#{datastream_name}][#{field_name}][#{z}]"
      
      result = field_selectors_for(datastream_name, field_key)
      choices.sort.each do |choice,label|
        if choice == selected_value
          result << tag(:input, :type=>"radio", :id=>"availability_#{choice}", :class=>"fedora-radio-button", :rel=>h_name, :name=>"asset[#{datastream_name}][#{h_name}][0]", :value=>choice.downcase, :checked=>true)
        else
          result << tag(:input, :type=>"radio", :id=>"availability_#{choice}", :class=>"fedora-radio-button", :rel=>h_name, :name=>"asset[#{datastream_name}][#{h_name}][0]", :value=>choice.downcase)
        end
        result << " <label>#{label}</label> "
      end
      result
    end
    return result
  end
  
  
  def fedora_text_field_insert_link(datastream_name, field_key, opts={})
    field_name = field_name_for(field_key) || field_key
    field_type = field_name == "person" ? "person" : "textfield"    
    link_text = "Add #{(opts[:label] || field_key.last || field_key).to_s.camelize.titlecase}"
    "<a class='addval #{field_type}' href='#' data-datastream-name=\"#{datastream_name}\" rel=\"#{field_name}\" title='#{link_text}'>#{link_text}</a>"
  end
  
  def fedora_text_area_insert_link(datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    link_text = "Add #{(opts[:label] || field_key.last || field_key).to_s.camelize.titlecase}"
    "<a class='addval textarea' href='#' data-datastream-name=\"#{datastream_name}\" rel=\"#{field_name}\" title='#{link_text}'>#{link_text}</a>"    
  end
  
  def fedora_field_label(datastream_name, field_key, label=nil)
    field_name = field_name_for(field_key)
    if label.nil?
      label = field_name
    end
    return content_tag "label", label, :for=>field_name
  end
  
  # Generate hidden inputs to handle mapping field names to server-side metadata mappings
  # this allows us to round-trip OM metadata mappings
  # also (importantly) allows us to avoid executing xpath queries from http requests.
  # *Note*: It's important that you serialize these inputs in order from top to bottom (standard HTML form behavior)
  def field_selectors_for(datastream_name, field_key)
    result = ""
    if field_key.kind_of?(Array)
      h_name = OM::XML::Terminology.term_hierarchical_name(*field_key)
      field_key.each do |pointer|
        if pointer.kind_of?(Hash)
          k = pointer.keys.first
          v = pointer.values.first
          # result << "<input type=\"hidden\", rel=\"#{h_name}\" name=\"field_selectors[#{datastream_name}][#{h_name}][][#{k}]\" value=\"#{v}\"/>"
          result << tag(:input, :type=>"hidden", :class=>"fieldselector", :rel=>h_name, :name=>"field_selectors[#{datastream_name}][#{h_name}][][#{k}]", :value=>v)
        else
          result << tag(:input, :type=>"hidden", :class=>"fieldselector", :rel=>h_name, :name=>"field_selectors[#{datastream_name}][#{h_name}][]", :value=>pointer.to_s)
        end
      end
    end
    return result
  end
  
  # hydra_form_for block helper 
  # allows you to construct an entire hydra form by passing a block into this method
  class HydraFormFor < BlockHelpers::Base

    def initialize(resource, opts={})
      @resource = resource
    end
    
    def fedora_label(datastream_name, field_key, opts={})
      helper.fedora_label(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_text_field(datastream_name, field_key, opts={})
      helper.fedora_label(@resource, datastream_name, field_key, opts)
    end

    def fedora_text_area(datastream_name, field_key, opts={})
      helper.fedora_text_area(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_select(datastream_name, field_key, opts={})
      helper.fedora_select(@resource, datastream_name, field_key, opts)
    end

    def fedora_submit(datastream_name, field_key, opts={})
      helper.fedora_submit(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_checkbox(datastream_name, field_key, opts={})
      helper.fedora_checkbox(@resource, datastream_name, field_key, opts)
    end
    
    def fedora_radio_button(datastream_name, field_key, opts={})
      helper.fedora_radio_button(@resource, datastream_name, field_key, opts)
    end    
    
    def fedora_text_field_insert_link(datastream_name, field_key, opts={})
      helper.fedora_text_field_insert_link(@resource, datastream_name, field_key, opts={})
    end
    
    def fedora_field_label(datastream_name, field_key, opts={})
      helper.fedora_field_label(@resource, datastream_name, field_key, opts)
    end

    def display(body)
      inner_html = content_tag :input, :type=>"hidden", :name=>"content_type", :value=>@resource.class.to_s.underscore
      inner_html = inner_html << body
      content_tag :form, inner_html
    end

  end
  
  #
  # Internal helper methods
  #
  
  # retrieve field values from datastream.
  # If :values is provided, skips accessing the datastream and returns the contents of :values instead.
  def get_values_from_datastream(resource, datastream_name, field_key, opts={})
    if opts.has_key?(:values)
      values = opts[:values]
      if values.nil? then values = [opts.fetch(:default, "")] end
    else
      values = resource.get_values_from_datastream(datastream_name, field_key, opts.fetch(:default, ""))
      if values.empty? then values = [ opts.fetch(:default, "") ] end
    end
    return values
  end
  
  def field_name_for(field_key)
    if field_key.kind_of?(Array)
      return OM::XML::Terminology.term_hierarchical_name(*field_key)
    else
      field_key.to_s
    end
  end
  
  def generate_base_id(field_name, current_value, values, opts)
    if opts.fetch(:multiple, true)
      return field_name+"_"+values.index(current_value).to_s
    else
      return field_name
    end
  end
  
end
