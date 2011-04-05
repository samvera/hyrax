module JavascriptIncludesHelper
  
  # Include the appropriate javascripts for the specified content type & action
  # @param [String] content_type
  # @param [String] action
  # @example
  # javascript_includes_for :hydrangea_articles, :edit 
  def javascript_includes_for(content_type, action, opts={})
    begin
      method_name = "javascript_includes_for_#{content_type}_#{action}"
      logger.debug "attempting to include #{method_name}"
      self.send(method_name.to_sym)
    rescue
      logger.debug "... no specific includes defined for #{content_type}.  Using defaults for #{action} views"
      default_javascript_includes( action )
    end
  end
  
  def default_javascript_includes( method )
    case method
    when "show"
      javascript_includes_for_catalog_show
    when "edit"
      javascript_includes_for_catalog_edit
    else
      logger.debug "No default javascript includes defined for #{method} views.  Doing nothing."
    end
  end
  
  def javascript_includes_for_catalog_show
    javascript_includes << ['custom', {:plugin=>:hydra_repository, :media=>"all"}] 
    
    # This file contains the page initialization scripts for catalog show views
    javascript_includes << ["catalog/show", {:plugin=>:hydra_repository, :media=>"all"}]
  end
  
  def javascript_includes_for_catalog_edit
    javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false)
    
    javascript_includes << ["jquery.jeditable.mini.js", {:plugin=>:hydra_repository, :media=>"all"}]
    javascript_includes << ["jquery.form.js", {:plugin=>:hydra_repository, :media=>"all"}]
    javascript_includes << ['custom', {:plugin=>:hydra_repository, :media=>"all"}]
    
    # This file contains the page initialization scripts for catalog edit views
    javascript_includes << ["catalog/edit", {:plugin=>:hydra_repository, :media=>"all"}]
    javascript_includes << ["jquery.hydraMetadata.js", {:plugin=>:hydra_repository, :media=>"all"}]
    javascript_includes << ["jquery.notice.js", {:plugin=>:hydra_repository, :media=>"all"}]
    
    javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>:hydra_repository}]
    javascript_includes << ["../infusion/components/undo/js/Undo.js", {:plugin=>:"fluid-infusion", :media=>"all"}]

    # For DatePicker
    javascript_includes << ["jquery.ui.widget.js","jquery.ui.datepicker.js", "mediashelf.datepicker.js", {:plugin=>:hydra_repository }]
    
    # For Fancybox
    javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>:hydra_repository}] 
    stylesheet_links << ["../javascripts/fancybox/jquery.fancybox-1.3.1.css", {:plugin=>:hydra_repository, :media=>"all"}] 

    # For slider controls 
    javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>:hydra_repository}] 
    stylesheet_links << ["../javascripts/select_to_ui_slider/css/ui.slider.extras.css", {:plugin=>:hydra_repository, :media=>"all"}] 
    stylesheet_links << ["slider", {:plugin=>:hydra_repository}] 
  end
  
  
  def javascript_includes_for_hydrangea_articles_edit
    javascript_includes_for_catalog_edit
    # add anything specific to hydrangea articles...
  end
  
  
end