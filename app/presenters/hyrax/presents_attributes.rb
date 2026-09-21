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

      values = send(field)
      options = renderer_options_for(field, values, options)
      renderer = renderer_for(field, options).new(field, values, options)

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

    def renderer_options_for(field, values, options)
      options = options.merge(subproperties: compound_subproperties_for(field)) if options[:render_as].to_s == 'compound'
      labels = controlled_labels_for(field, values)
      options = options.merge(labels: labels) if labels.present?
      options
    end

    # Keyed by value rather than position: AttributeRenderer sorts the values
    # when `options[:sort]` is set, so index-based pairing attaches the wrong
    # label. nil for an uncontrolled property, or a work indexed before the
    # label fields existed — the renderer then falls back to the ids.
    #
    # The counts must match exactly. A label service is contracted to return one
    # entry per value, but nothing enforces it, and zipping a short list shifts
    # every later label onto the wrong value — showing one term's label under
    # another term's id, which is worse than showing the id.
    def controlled_labels_for(field, values)
      @controlled_labels ||= {}
      return @controlled_labels[field] if @controlled_labels.key?(field)

      @controlled_labels[field] = compute_controlled_labels(field, values)
    end

    # Scans the document's keys, so it is memoized per field above: a show page
    # renders many fields against one document.
    def compute_controlled_labels(field, values)
      return unless respond_to?(:solr_document)

      document = solr_document
      return unless document.respond_to?(:[])

      values = Array(values).map(&:to_s)
      labels = indexed_labels_for(document, field)
      return if labels.blank? || labels.size != values.size

      values.zip(labels).to_h
    end

    # Read from the document rather than probed against a fixed suffix list: a
    # property can declare any index key (`creator_ssim`), and the indexer
    # writes a label companion for each.
    def indexed_labels_for(document, field)
      prefix = Hyrax::ControlledVocabularyFieldValues.label_prefix(field)
      pattern = /\A#{Regexp.escape(prefix)}_[^_]+\z/
      keys = document.keys.select { |key| key.to_s.match?(pattern) }
      # `_tesim` first, since `_sim` is indexed but not stored and usually reads
      # back empty; an empty key must fall through rather than end the search.
      keys.sort_by { |k| k.to_s.end_with?('_tesim') ? 0 : 1 }
          .lazy
          .filter_map { |key| Array(document[key]).presence }
          .first
    end

    # Normalized sub-property specs for a compound, so the renderer can translate
    # controlled ids to their terms; nil if the resource class can't be
    # resolved (the renderer then renders raw values).
    def compound_subproperties_for(field)
      return nil unless respond_to?(:solr_document) && solr_document.respond_to?(:hydra_model)
      # Resolve from the backing document, not the class: in flexible mode the
      # class carries no compounds, so a class lookup would drop the sub-property
      # specs and the renderer would fall back to raw (unlinked, untranslated)
      # values.
      Hyrax::CompoundSchema.for_solr_document(solr_document).definition_for(field)&.fetch(:subproperties, nil)
    rescue StandardError => e
      Hyrax.logger.debug("compound_subproperties_for(#{field}): #{e.message}")
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
