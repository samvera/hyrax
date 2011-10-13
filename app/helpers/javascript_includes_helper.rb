# Use this helper to declare which javascript should be loaded in which views
# Internally, it relies on include_javascript_for_#{controller}_#{action} helper methods 
# These helper methods will usually append their includes to the controller's javascript_includes array
#
# @example Within your views (or in your controllers), call the helper like this
#   include_javascript_for "hydrangea_articles", "edit"
#
# To declare your own array of includes for a specific content type or action, define a helper method in your host application or plugin like this
# @example Declaring the javascript includes for hydrangea_datasets show view while reusing the includes from catalog_edit
#   def include_javascript_for_hydrangea_datasets_show
#     include_javascript_for_catalog_edit
#     javascript_includes << ['hydrangeaArticleBehaviors.js', {:plugin=>:hydrangea_articles}]
#   end
module JavascriptIncludesHelper
  
  # Add the appropriate javascripts for the specified content type & action into the Controller's javascript_includes array
  # If you have defined custom javascript includes for that content_type & action, they will be used.
  # @param [String or Symbol] content_type
  # @param [String or Symbol] action
  # @example This will rely on the include_javascript_for_hydranea_articles_edit helper method if it's defined.  Defaults to calling include_default_javascript("edit")
  #   include_javascript_for "hydrangea_articles", "edit" 
  def include_javascript_for(content_type, action, opts={})
    begin
      method_name = "include_javascript_for_#{content_type.to_s}_#{action.to_s}"
      logger.debug "attempting to include #{method_name}"
      self.send(method_name.to_sym)
    rescue
      logger.debug "... no specific includes defined for #{content_type.to_s}.  Using defaults for #{action.to_s} views"
      include_default_javascript( action )
    end
  end
  
  # Add the default javascript to the controller's javascript_includes
  # Takes a method argument (ie. show or edit) to decide which defaults to use.
  # Currently configured to use the javascript includes for catalog show / edit.
  # @param [String or Symbol] method Currently only "show" and "edit" have defaults set
  def include_default_javascript(method)
    case method.to_s
    when "show"
      include_javascript_for_catalog_show
    when "edit"
      include_javascript_for_catalog_edit
    else
      logger.debug "No default javascript includes defined for #{method} views.  Doing nothing."
    end
  end
  
  #
  #   Helpers for Catalog Show & Edit Javascript Includes
  #
  
  # Adds the appropriate javascripts to javascript_includes for CatalogController show views
  # Override this if you want to change the set of javascript_includes for CatalogController show views
  def include_javascript_for_catalog_show
    javascript_includes << ['custom', {:plugin=>"hydra-head"}] 
    
    # This file contains the page initialization scripts for catalog show views
    javascript_includes << ["catalog/show", {:plugin=>"hydra-head"}]
  end
  
  # Adds the appropriate javascripts to javascript_includes for CatalogController edit views
  # Override this if you want to change the set of javascript_includes for CatalogController edit views
  def include_javascript_for_catalog_edit
    # This _would_ include the fluid infusion javascripts, but we don't want them
    # javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false)
    
    javascript_includes << ["jquery.jeditable.mini.js", {:plugin=>"hydra-head"}]
    javascript_includes << ["jquery.form.js", {:plugin=>"hydra-head"}]
    javascript_includes << ['custom', {:plugin=>"hydra-head"}]
    
    javascript_includes << ["jquery.hydraMetadata.js", {:plugin=>"hydra-head"}]
    javascript_includes << ["jquery.notice.js", {:plugin=>"hydra-head"}]
    
    javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}]
    # For DatePicker
    javascript_includes << ["jquery.ui.widget.js","jquery.ui.datepicker.js", "mediashelf.datepicker.js", {:plugin=>"hydra-head" }]
    
    # For Fancybox
    javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] 
    stylesheet_links << ["/javascripts/fancybox/jquery.fancybox-1.3.1.css", {:plugin=>"hydra-head"}] 

    # For slider controls 
    javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] 
    stylesheet_links << ["/javascripts/select_to_ui_slider/css/ui.slider.extras.css", {:plugin=>"hydra-head"}] 
    stylesheet_links << ["slider", {:plugin=>"hydra-head"}] 
    
    # This file contains the page initialization scripts for catalog edit views
    javascript_includes << ["catalog/edit", {:plugin=>"hydra-head"}]
  end
  
end