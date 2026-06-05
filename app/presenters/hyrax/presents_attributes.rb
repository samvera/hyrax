# frozen_string_literal: true
module Hyrax
  module PresentsAttributes
    ##
    # Present the attribute as an HTML table row or dl row.
    #
    # @param [Hash] options
    # @option options [Symbol] :render_as use an alternate renderer
    #   (e.g., :linked or :linked_attribute to use LinkedAttributeRenderer)
    # @option options [String] :search_field If the method_name of the attribute is different than
    #   how the attribute name should appear on the search URL,
    #   you can explicitly set the URL's search field name
    # @option options [String] :label The default label for the field if no translation is found
    # @option options [TrueClass, FalseClass] :include_empty should we display a row if there are no values?
    # @option options [String] :work_type name of work type class (e.g., "GenericWork")
    # @option options [TrueClass, FalseClass] :value_only render only the value
    #   markup, without the field-label row — used by compound cards, which
    #   already show the label as the card title.
    def attribute_to_html(field, options = {})
      unless respond_to?(field)
        Hyrax.logger.warn("#{self.class} attempted to render #{field}, but no method exists with that name.")
        return
      end

      options = options.merge(subfields: compound_subfields_for(field)) if options[:render_as].to_s == 'compound'
      renderer = renderer_for(field, options).new(field, send(field), options)

      if options[:value_only] && renderer.respond_to?(:render_value)
        renderer.render_value
      elsif options[:html_dl]
        renderer.render_dl_row
      else
        renderer.render
      end
    end

    def permission_badge
      permission_badge_class.new(solr_document.visibility).render
    end

    def permission_badge_class
      PermissionBadge
    end

    def display_microdata?
      Hyrax.config.display_microdata?
    end

    def microdata_type_to_html
      return "" unless display_microdata?
      value = Microdata.fetch(microdata_type_key, default: Hyrax.config.microdata_default_type)
      " itemscope itemtype=\"#{value}\"".html_safe
    end

    private

    # Normalized sub-field specs for a compound, so the renderer can translate
    # controlled ids to their terms; nil if the resource class can't be
    # resolved (the renderer then renders raw values).
    def compound_subfields_for(field)
      return nil unless respond_to?(:solr_document) && solr_document.respond_to?(:hydra_model)
      # Resolve from the backing document, not the class: in flexible mode the
      # class carries no compounds, so a class lookup would drop the sub-field
      # specs and the renderer would fall back to raw (unlinked, untranslated)
      # values.
      Hyrax::CompoundSchema.for_solr_document(solr_document).definition_for(field)&.fetch(:subfields, nil)
    rescue StandardError => e
      Hyrax.logger.debug("compound_subfields_for(#{field}): #{e.message}")
      nil
    end

    def find_renderer_class(name)
      renderer = nil
      ['Renderer', 'AttributeRenderer'].each do |suffix|
        const_name = "#{name.to_s.camelize}#{suffix}".to_sym
        renderer = begin
          Renderers.const_get(const_name)
                   rescue NameError
                     nil
        end
        break unless renderer.nil?
      end
      raise NameError, "unknown renderer type `#{name}`" if renderer.nil?
      renderer
    end

    def renderer_for(_field, options)
      if options[:render_as]
        find_renderer_class(options[:render_as])
      else
        Renderers::AttributeRenderer
      end
    end

    def microdata_type_key
      "resource_type.#{human_readable_type}"
    end
  end
end
