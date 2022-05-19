# frozen_string_literal: true

module Hyrax
  module FacetsHelper
    # Methods in this module are from Blacklight::FacetsHelperBehavior, blacklight v6.24.0
    # This module is used to ensure Hyrax facet views that rely on deprecated Blacklight helper methods are still functional

    include Blacklight::Facet

    ##
    # Renders the list of values
    # removes any elements where render_facet_item returns a nil value. This enables an application
    # to filter undesireable facet items so they don't appear in the UI
    def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
      safe_join(paginator.items.map { |item| render_facet_item(facet_field, item) }.compact.map { |item| content_tag(wrapping_element, item) })
    end

    ##
    # Renders a single facet item
    def render_facet_item(facet_field, item)
      if facet_in_params?(facet_field, item.value)
        render_selected_facet_value(facet_field, item)
      else
        render_facet_value(facet_field, item)
      end
    end

    ##
    # Standard display of a facet value in a list. Used in both _facets sidebar
    # partial and catalog/facet expanded list. Will output facet value name as
    # a link to add that to your restrictions, with count in parens.
    #
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [Blacklight::Solr::Response::Facets::FacetItem] item
    # @param [Hash] options
    # @option options [Boolean] :suppress_link display the facet, but don't link to it
    # @return [String]
    def render_facet_value(facet_field, item, options = {})
      path = path_for_facet(facet_field, item)
      content_tag(:span, class: "facet-label") do
        link_to_unless(options[:suppress_link], facet_display_value(facet_field, item), path, class: "facet_select")
      end + render_facet_count(item.hits)
    end

    ##
    # Where should this facet link to?
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [String] item
    # @return [String]
    def path_for_facet(facet_field, item)
      facet_config = facet_configuration_for_field(facet_field)
      if facet_config.url_method
        send(facet_config.url_method, facet_field, item)
      else
        search_action_path(search_state.add_facet_params_and_redirect(facet_field, item))
      end
    end

    ##
    # Standard display of a SELECTED facet value (e.g. without a link and with a remove button)
    # @see #render_facet_value
    # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
    # @param [String] item
    def render_selected_facet_value(facet_field, item)
      remove_href = search_action_path(search_state.remove_facet_params(facet_field, item))
      content_tag(:span, class: "facet-label") do
        content_tag(:span, facet_display_value(facet_field, item), class: "selected") +
          # remove link
          link_to(remove_href, class: "remove") do
            content_tag(:span, '', class: "glyphicon glyphicon-remove") +
              content_tag(:span, '[remove]', class: 'sr-only')
          end
      end + render_facet_count(item.hits, classes: ["selected"])
    end

    ##
    # Renders a count value for facet limits. Can be over-ridden locally
    # to change style. And can be called by plugins to get consistent display.
    #
    # @param [Integer] num number of facet results
    # @param [Hash] options
    # @option options [Array<String>]  an array of classes to add to count span.
    # @return [String]
    def render_facet_count(num, options = {})
      classes = (options[:classes] || []) << "facet-count"
      content_tag("span", t('blacklight.search.facets.count', number: number_with_delimiter(num)), class: classes)
    end

    ##
    # Check if the query parameters have the given facet field with the
    # given value.
    #
    # @param [Object] field
    # @param [Object] item facet value
    # @return [Boolean]
    def facet_in_params?(field, item)
      value = facet_value_for_facet_item(item)

      (facet_params(field) || []).include? value
    end

    ##
    # Get the values of the facet set in the blacklight query string
    def facet_params(field)
      config = facet_configuration_for_field(field)

      params[:f][config.key] if params[:f]
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @param [Object] field
    # @param [String] item value
    # @return [String]
    # rubocop:disable Metrics/MethodLength
    def facet_display_value(field, item)
      facet_config = facet_configuration_for_field(field)

      value = if item.respond_to? :label
                item.label
              else
                facet_value_for_facet_item(item)
              end

      if facet_config.helper_method
        send facet_config.helper_method, value
      elsif facet_config.query && facet_config.query[value]
        facet_config.query[value][:label]
      elsif facet_config.date
        localization_options = facet_config.date == true ? {} : facet_config.date

        l(value.to_datetime, localization_options)
      else
        value
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def facet_value_for_facet_item(item)
      if item.respond_to? :value
        item.value
      else
        item
      end
    end
  end
end
