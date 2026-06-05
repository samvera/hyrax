# frozen_string_literal: true

module Hyrax
  module Renderers
    ##
    # Renders a compound metadata attribute on a show page (selected via
    # `view: { render_as: compound }`). Each value is one entry — a hash of
    # sub-fields produced by the SolrDocument `compound_attribute` reader — and
    # renders as a block of its populated sub-fields. Sub-field labels come from
    # the `hyrax.compound_fields.<compound>.<subfield>` i18n keys.
    class CompoundAttributeRenderer < AttributeRenderer
      def render
        return '' if blank_values? && !options[:include_empty]

        %(<tr><th>#{label}</th>\n<td>#{entries_markup}</td></tr>).html_safe
      end

      def render_dl_row
        return '' if blank_values? && !options[:include_empty]

        %(<dt>#{label}</dt>\n<dd>#{entries_markup}</dd>).html_safe
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

        items = pairs.map { |sub_field, value| subfield_markup(sub_field, value) }.join
        %(<div class="hyrax-compound-entry">#{items}</div>)
      end

      def subfield_markup(sub_field, value)
        label_html = ERB::Util.h(sub_field_label(sub_field))
        %(<div class="hyrax-compound-subfield">) +
          %(<span class="hyrax-compound-subfield-label">#{label_html}:</span> ) +
          %(<span class="hyrax-compound-subfield-value">#{value_markup(sub_field, value)}</span>) +
          %(</div>)
      end

      # Display markup for one sub-field value, by sub-field type: `url` and
      # `work_or_url` are linked; otherwise escaped text with controlled ids
      # translated to their term.
      def value_markup(sub_field, value)
        return ERB::Util.h(display_value(sub_field, value)) if value.blank?

        case subfield_spec(sub_field)&.dig(:type).to_s
        when 'url'
          auto_link(ERB::Util.h(value.to_s))
        when 'work_or_url'
          work_or_url_markup(value)
        else
          ERB::Util.h(display_value(sub_field, value))
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

      def display_value(sub_field, value)
        Hyrax::CompoundSubfieldLabeler.label_for(subfield_spec(sub_field), value)
      end

      # The normalized sub-field spec, supplied by the caller via
      # `options[:subfields]`.
      def subfield_spec(sub_field)
        specs = options[:subfields]
        return nil unless specs.is_a?(Hash)
        specs[sub_field] || specs[sub_field.to_sym]
      end

      # Populated [sub_field, value] pairs for one entry; blanks dropped.
      def entry_to_pairs(entry)
        return [] unless entry.respond_to?(:each_pair) || entry.is_a?(::Hash)
        entry.to_h.each_with_object([]) do |(key, value), memo|
          next if value.blank?
          memo << [key.to_s, value]
        end
      end

      def sub_field_label(sub_field)
        I18n.t("hyrax.compound_fields.#{field}.#{sub_field}", default: sub_field.to_s.humanize)
      end
    end
  end
end
