module CurationConcerns::CatalogHelper
  def type_tab(label, key = label)
    if params[:f] && params[:f][type_field] == [key]
      content_tag(:li, link_to(label, '#'), class: 'active')
    else
      # TODO: Unused variable. Not sure why this is here.
      # facet_solr_field = facet_configuration_for_field(type_field)
      path = search_action_path(add_facet_params_and_redirect(type_field, key))
      # local_params = params.dup
      # local_facet_params = local_params[:f] || {}.with_indifferent_access
      # local_params[:f] = local_facet_params.select{|k,_| k != type_field }
      # puts "local #{local_params}"
      # path = add_facet_params(type_field, key, local_params)
      content_tag(:li, link_to(label, path))
    end
  end

  def all_type_tab(label = t('curation_concerns.catalog.index.type_tabs.all'))
    if params[:f] && params[:f][type_field]
      # TODO: Unused variable. Not sure why this is here.
      # facet_solr_field = facet_configuration_for_field(type_field)
      new_params = remove_facet_params(type_field, params[:f][type_field].first)

      # Delete any request params from facet-specific action, needed
      # to redir to index action properly.
      new_params.except!(*Blacklight::Solr::FacetPaginator.request_keys.values)
      path = search_action_path(new_params)
      content_tag(:li, link_to(label, path))
    else
      content_tag(:li, link_to(label, '#'), class: 'active')
    end
  end

  private

    def type_field
      Solrizer.solr_name('generic_type', :facetable)
    end
end
