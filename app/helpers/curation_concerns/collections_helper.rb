module CurationConcerns::CollectionsHelper
  def has_collection_search_parameters?
    params[:cq].present?
  end

  def collection_modal_id(collectible)
    "#{collectible.to_param.gsub(/:/, '-')}-modal"
  end

  def link_to_select_collection(collectible, opts = {})
    html_class = opts[:class]
    link_to '#', data: { toggle: 'modal', target: '#' + collection_modal_id(collectible) },
                 class: "add-to-collection #{html_class}", title: "Add #{collectible.human_readable_type} to Collection" do
      icon('plus-sign') + ' Add to a Collection'
    end
  end

  # override hydra-collections
  def link_to_remove_from_collection(document, label = 'Remove From Collection')
    link_to collections.collection_path(@collection.id, collection: { members: 'remove' },
                                                        batch_document_ids: [document.id]), method: :put do
      icon('minus-sign') + ' ' + label
    end
  end

  def icon(type)
    content_tag :span, '', class: "glyphicon glyphicon-#{type}"
  end

  def collection_options_for_select(exclude_item = nil)
    options_for_select(available_collections(exclude_item))
  end

  private

    # return a list of collections for the current user with the exception of the passed in collection
    def available_collections(exclude_item)
      if exclude_item
        collection_options.reject { |n| n.last == exclude_item.id }
      else
        collection_options
      end
    end

    def collection_options
      @collection_options ||= current_users_collections
    end

    # Defaults to returning a list of all collections.
    # If you have implement User.collections, the results of that will be used.
    def current_users_collections
      if current_user.respond_to?(:collections)
        current_user.collections.map { |c| [c.title.join(', '), c.id] }
      else
        query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: Collection.to_class_uri)
        ActiveFedora::SolrService.query(query, fl: 'title_tesim id', rows: 1000).map { |r| [r['title_tesim'].join(', '), r['id']] }.sort { |a, b| a.first <=> b.first }
      end
    end
end
