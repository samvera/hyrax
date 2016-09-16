module CurationConcerns::CollectionsHelper
  def has_collection_search_parameters?
    !params[:cq].blank?
  end

  def button_for_remove_from_collection(collection, document, label = 'Remove From Collection')
    render '/collections/button_remove_from_collection', collection: collection, label: label, document: document
  end

  def button_for_remove_selected_from_collection(collection, label = 'Remove From Collection')
    render '/collections/button_for_remove_selected_from_collection', collection: collection, label: label
  end

  # add hidden fields to a form for removing a single document from a collection
  def single_item_action_remove_form_fields(form, document)
    single_item_action_form_fields(form, document, 'remove')
  end

  # add hidden fields to a form for adding a single document to a collection
  def single_item_action_add_form_fields(form, document)
    single_item_action_form_fields(form, document, 'add')
  end

  # add hidden fields to a form for performing an action on a single document on a collection
  def single_item_action_form_fields(form, document, action)
    render '/collections/single_item_action_fields', form: form, document: document, action: action
  end

  def hidden_collection_members
    erbout = ''
    if params[:batch_document_ids].present?
      params[:batch_document_ids].each do |batch_item|
        erbout.concat hidden_field_tag('batch_document_ids[]', batch_item)
      end
    end
    erbout.html_safe
  end

  def collection_modal_id(collectible)
    "#{collectible.to_param.tr(':', '-')}-modal"
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
    collection_id = @collection ? @collection.id : @presenter.id
    link_to collection_path(collection_id, collection: { members: 'remove' },
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
        return current_user.collections.map { |c| [c.title.join(', '), c.id] }
      end
      service = CurationConcerns::CollectionsService.new(controller)
      convert_solr_docs_to_select_options(service.search_results(:edit))
    end

    def convert_solr_docs_to_select_options(results)
      option_values = results.map do |r|
        title = r.title
        [title.present? ? title.join(', ') : nil, r.id]
      end
      option_values.sort do |a, b|
        if a.first && b.first
          a.first <=> b.first
        else
          a.first ? -1 : 1
        end
      end
    end
end
