module CurationConcerns
  module AttributeHelper

    # If options[:catalog_search_link] is false,
    # it will return the attribute value as text.
    # If options[:catalog_search_link] is true,
    # it will return a link to a catalog search for that text.
    #
    # If the method_name of the attribute is different than
    # how the attribute name should appear on the search URL,
    # you can explicitly set the URL's search field name using
    # options[:search_field].
    def curation_concern_attribute_to_html(curation_concern, method_name, label = nil, options = {})
      if curation_concern.respond_to?(method_name)
        markup = ""
        label ||= derived_label_for(curation_concern, method_name)
        subject = curation_concern.send(method_name)
        return markup if !subject.present? && !options[:include_empty]
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
        [subject].flatten.compact.each do |value|
          if method_name == :rights
            # Special treatment for license/rights.  A URL from the Sufia gem's config/sufia.rb is stored in the descMetadata of the
            # curation_concern.  If that URL is valid in form, then it is used as a link.  If it is not valid, it is used as plain text.
            parsedUri = URI.parse(value) rescue nil
            if parsedUri.nil?
              markup << %(<li class="attribute #{method_name}">#{h(value)}</li>\n)
            else
              markup << %(<li class="attribute #{method_name}"><a href=#{h(value)} target="_blank"> #{h(Sufia.config.cc_licenses_reverse[value])}</a></li>\n)
            end
          else
            search_field = options[:search_field] || method_name
            li_value = link_to_if(options[:catalog_search_link], h(value), main_app.catalog_index_path(search_field: search_field, q: h(value)))
            markup << %(<li class="attribute #{method_name}"> #{li_value} </li>\n)
          end
        end
        markup << %(</ul></td></tr>)
        markup.html_safe
      end
    end

    def permission_badge_for(curation_concern, solr_document = nil)
      solr_document ||= curation_concern.to_solr
      dom_label_class, link_title = extract_dom_label_class_and_link_title(solr_document)
      %(<span class="label #{dom_label_class}" title="#{link_title}">#{link_title}</span>).html_safe
    end

    private
      def extract_dom_label_class_and_link_title(document)
        hash = document.stringify_keys
        dom_label_class, link_title = "label-danger", "Private"
        if hash[Hydra.config.permissions.read.group].present?
          if hash[Hydra.config.permissions.read.group].include?('public')
            if hash[Hydra.config.permissions.embargo.release_date].present?
              dom_label_class, link_title = 'label-warning', 'Open Access with Embargo'
            else
              dom_label_class, link_title = 'label-success', 'Open Access'
            end
          elsif hash[Hydra.config.permissions.read.group].include?('registered')
            dom_label_class, link_title = "label-info", t('sufia.institution_name')
          end
        end
        return dom_label_class, link_title
      end


  end
end
