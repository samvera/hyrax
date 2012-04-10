module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  # @override to remove the label class (easier integration with bootstrap)
  def render_facet_value(facet_solr_field, item, options ={})    
    (link_to_unless(options[:suppress_link], item.value, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
  end
end
