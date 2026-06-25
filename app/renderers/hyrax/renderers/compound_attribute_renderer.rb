# frozen_string_literal: true

module Hyrax
  module Renderers
    ##
    # Renders a compound metadata attribute on a show page (selected via
    # `view: { render_as: compound }`). Each value is one entry — a hash of
    # sub-properties produced by the SolrDocument `compound_attribute` reader —
    # and renders as a block of its populated sub-properties. Sub-property labels
    # come from the `hyrax.compound_fields.<compound>.<subproperty>` i18n keys.
    class CompoundAttributeRenderer < AttributeRenderer
      def render
        return '' if blank_values? && !options[:include_empty]

        %(<tr><th>#{label}</th>\n<td>#{entries_markup}</td></tr>).html_safe
      end

      def render_dl_row
        return '' if blank_values? && !options[:include_empty]

        # Wrap in the same `ul.tabular` structure ordinary fields use, so inline
        # compound values inherit the same indentation as the surrounding
        # metadata (whatever an app/theme styles `ul.tabular` to) rather than a
        # fixed pad that misaligns downstream.
        %(<dt>#{label}</dt>\n<dd><ul class="tabular"><li class="attribute attribute-#{field}">#{entries_markup}</li></ul></dd>).html_safe
      end

      # Just the entry rows, without a surrounding label/row wrapper. Used by
      # views that supply their own `<dt>`/`<dd>` (e.g. the collection show
      # descriptions), so the markup isn't double-nested.
      def render_value
        return '' if blank_values? && !options[:include_empty]

        entries_markup.html_safe
      end

      private

      def blank_values?
        Array(values).reject { |entry| entry_to_pairs(entry).empty? }.empty?
      end

      def entries_markup
        rows = Array(values).map { |entry| entry_markup(entry) }.reject(&:blank?)
        # Plain <div>s (not <dl>/<dt>/<dd>) so entries don't inherit the metadata
        # list's divider/border styling, which would draw stray lines.
        %(<div class="hyrax-compound-values">#{rows.join}</div>)
      end

      def entry_markup(entry)
        pairs = entry_to_pairs(entry)
        return '' if pairs.empty?

        items = pairs.map { |sub_property, value| subproperty_markup(sub_property, value) }.join
        %(<div class="hyrax-compound-entry">#{items}</div>)
      end

      def subproperty_markup(sub_property, value)
        label_html = ERB::Util.h(sub_property_label(sub_property))
        %(<div class="hyrax-compound-subproperty">) +
          %(<span class="hyrax-compound-subproperty-label">#{label_html}:</span> ) +
          %(<span class="hyrax-compound-subproperty-value">#{value_markup(sub_property, value)}</span>) +
          %(</div>)
      end

      # Display markup for one sub-property value, by sub-property type: `url` and
      # `work_or_url` are linked; otherwise escaped text with controlled ids
      # translated to their term.
      def value_markup(sub_property, value)
        return ERB::Util.h(display_value(sub_property, value)) if value.blank?

        case subproperty_spec(sub_property)&.dig(:type).to_s
        when 'url'
          auto_link(ERB::Util.h(value.to_s))
        when 'work_or_url'
          work_or_url_markup(value)
        when 'linked_record'
          linked_record_markup(sub_property, value)
        when 'controlled'
          controlled_markup(sub_property, value)
        else
          ERB::Util.h(display_value(sub_property, value))
        end
      end

      # Resolve a `linked_record` reference (a row id) to the record's label,
      # linked to its show path, via the sub-property's registered source
      # (`spec[:authority]`). The link text prefers the profile-declared
      # `view: { label_field: }`, else the source's registered label proc.
      # Renders the bare id when it doesn't resolve, so the link is never broken.
      def linked_record_markup(sub_property, value)
        spec = subproperty_spec(sub_property)
        label, path = Hyrax::CompoundLinkedRecordResolver.title_and_path(
          spec&.dig(:authority), value, label_field: spec&.dig(:label_field)
        )
        # When there's no path (record resolves but its `path:` proc returns
        # blank, or it doesn't resolve), render the resolved label as plain text
        # — `label` is the record's label when resolved, else the id string — so
        # a resolved name is never discarded in favor of the bare id.
        return ERB::Util.h(label.to_s) if path.blank?

        link_to(ERB::Util.h(label), path)
      end

      # A controlled value displays its authority/value-list term. When the
      # stored value is itself a linkable URI (e.g. a rights-statement or license
      # URI), link the term to that URI — mirroring the ordinary rights/license
      # renderer. Non-URI controlled values (e.g. inline option ids) stay plain.
      def controlled_markup(sub_property, value)
        label = display_value(sub_property, value)
        if Hyrax::AuthorityRenderingHelper.linkable_uri?(value)
          %(<a href="#{ERB::Util.h(value)}" target="_blank" rel="noopener noreferrer">#{ERB::Util.h(label)}</a>).html_safe
        else
          ERB::Util.h(label)
        end
      end

      # Link a URL or a resolvable work; render anything else as plain text so
      # we never emit a broken link to a non-existent work.
      def work_or_url_markup(value)
        return auto_link(ERB::Util.h(value.to_s)) if Hyrax::CompoundWorkResolver.url?(value)

        title, path = Hyrax::CompoundWorkResolver.resolve(value)
        return ERB::Util.h(value.to_s) if title.nil?
        link_to(ERB::Util.h(title), path)
      end

      def display_value(sub_property, value)
        Hyrax::CompoundSubpropertyLabeler.label_for(subproperty_spec(sub_property), value)
      end

      # The normalized sub-property spec, supplied by the caller via
      # `options[:subproperties]`.
      def subproperty_spec(sub_property)
        specs = options[:subproperties]
        return nil unless specs.is_a?(Hash)
        specs[sub_property] || specs[sub_property.to_sym]
      end

      # Populated [sub_property, value] pairs for one entry; blanks dropped.
      def entry_to_pairs(entry)
        return [] unless entry.respond_to?(:each_pair) || entry.is_a?(::Hash)
        entry.to_h.each_with_object([]) do |(key, value), memo|
          next if value.blank?
          memo << [key.to_s, value]
        end
      end

      def sub_property_label(sub_property)
        I18n.t("hyrax.compound_fields.#{field}.#{sub_property}", default: sub_property.to_s.humanize)
      end
    end
  end
end
