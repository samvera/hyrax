module CurationConcerns
  module PresentsAttributes
    ##
    # Present the attribute as an HTML table row.
    #
    # @param [Hash] options
    # @option options [true, false] :catalog_search_link return a link to a catalog search for that text if true
    # @option options [String] :search_field If the method_name of the attribute is different than
    #   how the attribute name should appear on the search URL,
    #   you can explicitly set the URL's search field name
    # @option options [String] :label The default label for the field if no translation is found
    def attribute_to_html(field, options = {})
      return unless respond_to?(field)
      AttributeRenderer.new(field, send(field), options).render
    end

    def permission_badge
      permission_badge_class.new(solr_document).render
    end

    def permission_badge_class
      PermissionBadge
    end
  end
end
