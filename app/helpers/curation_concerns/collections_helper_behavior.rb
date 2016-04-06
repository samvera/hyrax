# View Helpers for Hydra Collections functionality
module CurationConcerns
  module CollectionsHelperBehavior
    def has_collection_search_parameters?
      !params[:cq].blank?
    end

    # Displays the Collections create collection button.  Put this in your search result page template.  We recommend putting it in catalog/_sort_and_per_page.html.erb
    def button_for_create_collection(label = 'Create Collection')
      render '/collections/button_create_collection', label: label
    end

    # Displays the Collections update collection button.  Put this in your search result page template.  We recommend putting it in catalog/_sort_and_per_page.html.erb
    def button_for_update_collection(label = 'Update Collection', collection_id = 'collection_replace_id')
      render '/collections/button_for_update_collection', label: label, collection_id: collection_id
    end

    # Displays the Collections delete collection button.  Put this in your search result page for each collection found.
    def button_for_delete_collection(collection, label = 'Delete Collection', confirm = 'Are you sure?')
      render '/collections/button_for_delete_collection', collection: collection, label: label, confirm: confirm
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
  end
end
