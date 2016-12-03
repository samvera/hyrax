require "rails_autolink/helpers"

module Hyrax
  module Renderers
    class AttributeRenderer
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::TranslationHelper
      include ActionView::Helpers::TextHelper
      include ConfiguredMicrodata

      attr_reader :field, :values, :options

      # @param [Symbol] field
      # @param [Array] values
      # @param [Hash] options
      def initialize(field, values, options = {})
        @field = field
        @values = values
        @options = options
      end

      # Draw the table row for the attribute
      def render
        markup = ''

        return markup if !values.present? && !options[:include_empty]
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute #{field}")
        Array(values).each do |value|
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end
        markup << %(</ul></td></tr>)
        markup.html_safe
      end

      # @return The human-readable label for this field.
      # @note This is a central location for determining the label of a field
      #   name. Can be overridden if more complicated logic is needed.
      def label
        translate(
          :"blacklight.search.fields.show.#{field}",
          default: [:"blacklight.search.fields.#{field}", options.fetch(:label, field.to_s.humanize)]
        )
      end

      private

        def attribute_value_to_html(value)
          if microdata_value_attributes(field).present?
            "<span#{html_attributes(microdata_value_attributes(field))}>#{li_value(value)}</span>"
          else
            li_value(value)
          end
        end

        def html_attributes(attributes)
          buffer = ""
          attributes.each do |k, v|
            buffer << " #{k}"
            buffer << %(="#{v}") unless v.blank?
          end
          buffer
        end

        def li_value(value)
          auto_link(ERB::Util.h(value))
        end
    end
  end
end
