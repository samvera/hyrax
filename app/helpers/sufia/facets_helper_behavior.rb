module Sufia
  module FacetsHelperBehavior
    include Hydra::FacetsHelperBehavior

    # Override to remove the label class (easier integration with bootstrap)
    # and handles arrays
    def render_facet_value(facet_solr_field, item, options ={})
      logger.warn "display value #{ facet_display_value(facet_solr_field, item)}"
      if item.is_a? Array
        render_array_facet_value(facet_solr_field, item, options)
      end
      if params[:controller] == "dashboard"
        path = sufia.url_for(add_facet_params_and_redirect(facet_solr_field,item.value ).merge(:only_path=>true))
        (link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
      else
        # This is for controllers that use this helper method that are defined outside Sufia
        path = url_for(add_facet_params_and_redirect(facet_solr_field, item.value).merge(:only_path=>true))
        (link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
      end
    end

  end
end
