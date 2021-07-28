# frozen_string_literal: true
require "rails_autolink/helpers"

module Hyrax
  module Renderers
    class AttributeRenderer
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::TranslationHelper
      include ActionView::Helpers::TextHelper
      include ConfiguredMicrodata

      attr_reader :field, :values, :options

      ##
      # @param [Symbol] field
      # @param [Array] values
      # @param [Hash] options
      # @option options [String] :label The field label to render
      # @option options [String] :include_empty Do we render if if the values are empty?
      # @option options [String] :work_type Used for some I18n logic
      # @option options [Boolean] :sort sort the values with +Array#sort+ if truthy
      def initialize(field, values, options = {})
        @field = field
        @values = values
        @options = options
      end

      # Draw the table row for the attribute
      def render
        return '' if values.blank? && !options[:include_empty]

        markup = %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)

        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")

        values_array = Array(values)
        values_array = values_array.sort if options[:sort]

        markup += values_array.map do |value|
          "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end.join

        markup += %(</ul></td></tr>)

        markup.html_safe
      end

      # Draw the dl row for the attribute
      def render_dl_row
        return '' if values.blank? && !options[:include_empty]

        markup = %(<dt>#{label}</dt>\n<dd><ul class='tabular'>)

        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")

        values_array = Array(values)
        values_array.sort! if options[:sort]

        markup += values_array.map do |value|
          "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
        end.join
        markup += %(</ul></dd>)

        markup.html_safe
      end

      # Defaults to the label provided in the options, otherwise, it
      # fallsback to the inner logic of the method.
      #
      # @return The human-readable label for this field.
      # @note This is a central location for determining the label of a field
      #   name. Can be overridden if more complicated logic is needed.
      def label
        if options&.key?(:label)
          options.fetch(:label)
        else
          translate(
            :"blacklight.search.fields.#{work_type_label_key}.show.#{field}",
            default: [:"blacklight.search.fields.show.#{field}",
                      :"blacklight.search.fields.#{field}",
                      field.to_s.humanize]
          )
        end
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
        attributes.map do |key, value|
          value_set = value.present? ? %(="#{value}") : nil
          " #{key}#{value_set}"
        end.join
      end

      def li_value(value)
        auto_link(ERB::Util.h(value))
      end

      def work_type_label_key
        options[:work_type] ? options[:work_type].underscore : nil
      end
    end
  end
end
