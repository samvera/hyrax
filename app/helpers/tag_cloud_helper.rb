module TagCloudHelper
  
  def tag_cloud_for(field_name, options={})
    # display_facet = facets_from_request([field_name]).first
    display_facet = facet_by_field_name(field_name)
    unless display_facet.nil? || display_facet.items.empty?
      options = options.dup
      options[:granularity] ||= 15.0
      options[:partial] ||= "catalog/tag_cloud"
      # options[:layout] ||= "facet_layout" unless options.has_key?(:layout)
      options[:locals] ||= {}
      options[:locals][:solr_field] ||= display_facet.name 
      options[:locals][:facet_field] ||= facet_configuration_for_field(display_facet.name)
      options[:locals][:display_facet] ||= display_facet 
      options[:locals][:scale_factor] ||= calculate_scale_factor(display_facet.items, options[:granularity])     
      options[:locals][:limit] ||= options[:limit] ||= display_facet.items.length                                                             
      render(options)
    end
  end
  
  # Calculates the weight of the item's hits, relative to the provided step_size
  def tag_weight_for(item, scale_factor=1/25)
    (item.hits*scale_factor).round
  end
  
  private
  
  # Returns the appropriate scale factor for achieving the desired granularity with a given set of items
  def calculate_scale_factor(items, granularity)
    hit_counts = items.map {|i| i.hits}
    # len = hit_counts.length
    # median = len % 2 == 1 ? hit_counts[len/2] : (hit_counts[len/2 - 1] + hit_counts[len/2]).to_f / 2
    if hit_counts.max.nil?
      1
    else
      1/(hit_counts.max/granularity.to_f)
    end
  end
end