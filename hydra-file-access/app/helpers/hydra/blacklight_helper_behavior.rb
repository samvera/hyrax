require 'deprecation'
module Hydra
  module BlacklightHelperBehavior
    extend Deprecation
    include Blacklight::BlacklightHelperBehavior
    
    self.deprecation_horizon = 'hydra-head 5.x'
    
    def get_data_with_linked_label(doc, label, field_string, opts={})
      (opts[:default] and !doc[field_string]) ? field = opts[:default] : field = doc[field_string]
      delim = opts[:delimiter] ? opts[:delimiter] : "<br/>"
      if doc[field_string]
        text = "<dt>#{label}</dt><dd>"
        if field.respond_to?(:each)
          text += field.map do |l| 
            linked_label(l, field_string)
          end.join(delim)
        else
          text += linked_label(field, field_string)
        end
        text += "</dd>"
        text
      end
    end
    deprecation_deprecate :get_data_with_linked_label
    
    def linked_label(field, field_string)
      link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
    end
    deprecation_deprecate :linked_label

    # currently only used by the render_document_partial helper method (below)
    def document_partial_name(document)
      display_type = document[blacklight_config.show.display_type]

      return 'default' unless display_type 

      display_type.first.gsub(/^[^\/]+\/[^:]+:/,"").underscore.pluralize
    end

    def document_partial_path_templates
      ["%2$s/%1$s"] + super
    end
    
    def render_complex_facet_value(facet_solr_field, item, options ={})    
      link_to_unless(options[:suppress_link], format_item_value(item.value), add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
    end
    deprecation_deprecate :render_complex_facet_value

    def render_journal_facet_value(facet_solr_field, item, options ={})
      val = item.value.strip.length > 12 ? item.value.strip[0..12].concat("...") : item.value.strip
      link_to_unless(options[:suppress_link], val, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
    end
    deprecation_deprecate :render_journal_facet_value

    def render_complex_facet_image(facet_solr_field, item, options = {})
      computing_id = extract_computing_id(item.value)
      if File.exists?("#{Rails.root}/public/images/faculty_images/#{computing_id}.jpg")
        img = image_tag "/images/faculty_images/#{computing_id}.jpg", :width=> "100", :alt=>"#{item.value}"
      else
        img = image_tag "/plugin_assets/hydra-head/images/default_thumbnail.gif", :width=>"100", :alt=>"#{item.value}"
      end
      link_to_unless(options[:suppress_link], img, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select facet_image") 
    end
    deprecation_deprecate :render_complex_facet_image

    def render_journal_image(facet_solr_field, item, options = {})
      if File.exists?("#{Rails.root}/public/images/journal_images/#{item.value.strip.downcase.gsub(/\s+/,'_')}.jpg")
        img = image_tag "/images/journal_images/#{item.value.strip.downcase.gsub(/\s+/,'_')}.jpg", :width => "100"
      else
        img = image_tag "/plugin_assets/hydra-head/images/default_thumbnail.gif", :width=>"100", :alt=>"#{item.value}"
      end

      link_to_unless(options[:suppress_link], img, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") 
    end
    deprecation_deprecate :render_journal_image

    def get_randomized_display_items items
      clean_items = items.each.inject([]) do |array, item|
        array << item unless item.value.strip.blank?
        array
      end

      if clean_items.length < 6 
        clean_items.sort_by {|item| item.value }
      else 
        rdi = clean_items.sort_by {rand}.slice(0..5)
        return rdi.sort_by {|item| item.value.downcase}
      end
    end
    deprecation_deprecate :get_randomized_display_items

    def extract_computing_id val
      cid = val.split(" ")[-1]
      cid[1..cid.length-2]
    end
    deprecation_deprecate :extract_computing_id

    def format_item_value val
      begin
        last, f_c = val.split(", ")
        first = f_c.split(" (")[0]
      rescue
        return val.nil? ? "" : val
      end
      [last, "#{first[0..0]}."].join(", ")
    end
    deprecation_deprecate :format_item_value

  #   COPIED from vendor/plugins/blacklight/app/helpers/application_helper.rb
    # Used in catalog/facet action, facets.rb view, for a click
    # on a facet value. Add on the facet params to existing
    # search constraints. Remove any paginator-specific request
    # params, or other request params that should be removed
    # for a 'fresh' display. 
    # Change the action to 'index' to send them back to
    # catalog/index with their new facet choice. 
    def add_facet_params_and_redirect(field, value)
      new_params = super

      # Delete :qt, if needed - added to resolve NPE errors
      new_params.delete(:qt)

      new_params
    end

  end
end
