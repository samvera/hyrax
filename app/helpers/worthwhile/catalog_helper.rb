module Worthwhile::CatalogHelper 
  def type_tab(label, key=label)
    if params[:f] && params[:f][type_field] == [key]
      content_tag(:li, link_to(label, "#"), class: "active")
    else
      local_params = params.dup
      local_facet_params = local_params[:f] || {}.with_indifferent_access
      local_params[:f] = local_facet_params.select{|k,_| k != type_field }
      content_tag(:li, link_to(label, add_facet_params(type_field, key, local_params)))
    end
  end

  def all_type_tab(label = t('worthwhile.catalog.index.type_tabs.all'))
    if params[:f] && params[:f][type_field]
      local_params = params.dup
      local_params[:f] = local_params[:f].select{|k,_| k != type_field }
      local_params.delete(:f) if local_params[:f].empty?
      content_tag(:li, link_to(label, local_params))
    else
      content_tag(:li, link_to(label, '#'), class: "active")
    end
  end

  private

    def type_field
      Solrizer.solr_name("generic_type", :facetable)
    end

end
