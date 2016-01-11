require "rails_autolink/helpers"

module CurationConcerns
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
        default: [:"blacklight.search.fields.#{field}", options.fetch(:label, field.to_s.humanize)])
    end

    private

      def attribute_value_to_html(value)
        if field == :rights
          rights_attribute_to_html(value)
        elsif microdata_value_attributes(field).present?
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

      def search_field
        options.fetch(:search_field, field)
      end

      def li_value(value)
        if options[:catalog_search_link]
          link_to(ERB::Util.h(value), search_path(value))
        else
          auto_link(value)
        end
      end

      def search_path(value)
        Rails.application.routes.url_helpers.catalog_index_path(
          search_field: search_field, q: ERB::Util.h(value))
      end

      ##
      # Special treatment for license/rights.  A URL from the Sufia gem's config/sufia.rb is stored in the descMetadata of the
      # curation_concern.  If that URL is valid in form, then it is used as a link.  If it is not valid, it is used as plain text.
      def rights_attribute_to_html(value)
        begin
          parsed_uri = URI.parse(value)
        rescue
          nil
        end
        if parsed_uri.nil?
          ERB::Util.h(value)
        else
          %(<a href=#{ERB::Util.h(value)} target="_blank">#{RightsService.label(value)}</a>)
        end
      end
  end
end
