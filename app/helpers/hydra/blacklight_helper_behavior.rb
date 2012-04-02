require "hydra_helper"
require 'blacklight/blacklight_helper_behavior'

module Hydra
  module BlacklightHelperBehavior
    include Blacklight::BlacklightHelperBehavior
    include HydraHelper
    
    def application_name
      'A Hydra Head'
    end
    
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
    
    def linked_label(field, field_string)
      link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
    end

    # currently only used by the render_document_partial helper method (below)
    def document_partial_name(document)
      display_type = document[blacklight_config.show.display_type]

      return 'default' unless display_type 

      display_type.first.gsub(/^[^\/]+\/[^:]+:/,"").underscore.pluralize
    end

    def document_partial_path_templates
      ["%2$s/%1$s"] + super
    end
    
    # Removing the [remove] link from the default selected facet display
    def render_selected_facet_value(facet_solr_field, item)
      content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected label")
    end

    
    ###
    ### Overrides pulled in from Libra
    ###
    
    def render_facet_value(facet_solr_field, item, options ={})
      if item.is_a? Array
        return link_to_unless(options[:suppress_link], item[0], add_facet_params_and_redirect(facet_solr_field, item[0]), :class=>"facet_select") + " (" + format_num(item[1]) + ")" 
      end

      super
    end

    def render_complex_facet_value(facet_solr_field, item, options ={})    
      link_to_unless(options[:suppress_link], format_item_value(item.value), add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
    end

    def render_journal_facet_value(facet_solr_field, item, options ={})

      val = item.value.strip.length > 12 ? item.value.strip[0..12].concat("...") : item.value.strip
      link_to_unless(options[:suppress_link], val, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" 
    end

    def render_complex_facet_image(facet_solr_field, item, options = {})
      computing_id = extract_computing_id(item.value)
      if File.exists?("#{Rails.root}/public/images/faculty_images/#{computing_id}.jpg")
        img = image_tag "/images/faculty_images/#{computing_id}.jpg", :width=> "100", :alt=>"#{item.value}"
      else
        img = image_tag "/plugin_assets/hydra-head/images/default_thumbnail.gif", :width=>"100", :alt=>"#{item.value}"
      end
      link_to_unless(options[:suppress_link], img, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select facet_image") 
    end

    def render_journal_image(facet_solr_field, item, options = {})
      if File.exists?("#{Rails.root}/public/images/journal_images/#{item.value.strip.downcase.gsub(/\s+/,'_')}.jpg")
        img = image_tag "/images/journal_images/#{item.value.strip.downcase.gsub(/\s+/,'_')}.jpg", :width => "100"
      else
        img = image_tag "/plugin_assets/hydra-head/images/default_thumbnail.gif", :width=>"100", :alt=>"#{item.value}"
      end

      link_to_unless(options[:suppress_link], img, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") 
    end

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

    def extract_computing_id val
      cid = val.split(" ")[-1]
      cid[1..cid.length-2]
    end

    def format_item_value val
      begin
        last, f_c = val.split(", ")
        first = f_c.split(" (")[0]
      rescue
        return val.nil? ? "" : val
      end
      [last, "#{first[0..0]}."].join(", ")
    end

    def render_head_content
      render_stylesheet_includes +
      render_js_includes +
      render_extra_head_content_without_unapi +
      content_for(:head)
    end

    def render_extra_head_content_without_unapi
      remove_unapi! 
      render_extra_head_content
    end 

    # rel="unapi-server" is not HTML5 valid.  Need to see if there is a way to do that properly while still validating.
    def remove_unapi!
      extra_head_content.delete_if do |ehc|
        ehc.include?("unapi-server")
      end
    end

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
