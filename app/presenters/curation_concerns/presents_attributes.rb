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
      dom_label_class, link_title = extract_dom_label_class_and_link_title(solr_document)
      %(<span class="label #{dom_label_class}" title="#{link_title}">#{link_title}</span>).html_safe
    end

    private

      def extract_dom_label_class_and_link_title(document)
        hash = document.stringify_keys
        dom_label_class = 'label-danger'
        link_title = 'Private'
        if hash[Hydra.config.permissions.read.group].present?
          if hash[Hydra.config.permissions.read.group].include?('public')
            if hash[Hydra.config.permissions.embargo.release_date].present?
              dom_label_class = 'label-warning'
              link_title = 'Open Access with Embargo'
            else
              dom_label_class = 'label-success'
              link_title = 'Open Access'
            end
          elsif hash[Hydra.config.permissions.read.group].include?('registered')
            dom_label_class = 'label-info'
            link_title = I18n.translate('curation_concerns.institution_name')
          end
        end
        [dom_label_class, link_title]
      end
  end
end
