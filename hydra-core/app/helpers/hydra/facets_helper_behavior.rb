module Hydra
  module FacetsHelperBehavior
    include Blacklight::FacetsHelperBehavior

    # Removing the [remove] link and label class from the default selected facet display
    def render_selected_facet_value(facet_solr_field, item)
      content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected")
    end

    # Override to remove the label class (easier integration with bootstrap)
    # and handles arrays
    def render_facet_value(facet_solr_field, item, options ={})    
      if item.is_a? Array
        render_array_facet_value(facet_solr_field, item, options)
      end

      (link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
    end

    def render_array_facet_value(facet_solr_field, item, options)
      (link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item[0]), add_facet_params_and_redirect(facet_solr_field, item[0]), :class=>"facet_select") + " (" + format_num(item[1]) + ")").html_safe 
    end
  end
end

