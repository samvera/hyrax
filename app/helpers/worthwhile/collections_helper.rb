module Worthwhile::CollectionsHelper
  def has_collection_search_parameters?
    params[:cq].present?
  end

  def collection_modal_id(collectible)
    "#{collectible.to_param.gsub(/:/, '-')}-modal"
  end

  def link_to_select_collection(collectible, opts={})
    html_class = opts[:class]
    link_to add_member_form_collections_path(collectible_id: collectible.id),
      data: { toggle: "modal", target: '#' + collection_modal_id(collectible) },
      class: "add-to-collection #{html_class}", title: "Add #{collectible.human_readable_type} to Collection" do
      icon('plus-sign') + ' Add to a Collection'
    end
  end

  # override hydra-collections
  def link_to_remove_from_collection(document, label = 'Remove From Collection')
    link_to collections.collection_path(@collection.id, collection: { members: 'remove'},
                batch_document_ids: [ document.id ]), method: :put do
      icon('minus-sign') + ' ' + label
    end
  end

  def icon(type)
    content_tag :span, '', class: "glyphicon glyphicon-#{type}"
  end

end
