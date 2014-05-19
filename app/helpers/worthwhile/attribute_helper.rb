module Worthwhile
  module AttributeHelper
    # options[:include_empty]
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
            li_value = if options[:catalog_search_link]
                       link_to(h(value), catalog_index_path(search_field: method_name, q: h(value)))
                       else
                         h(value)
                       end
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
            if hash[Hydra.config.permissions.embargo_release_date].present?
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
