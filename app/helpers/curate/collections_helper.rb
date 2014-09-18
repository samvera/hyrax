# View Helpers for Hydra Collections functionality
module Curate::CollectionsHelper

  def button_for_remove_item_from_collection(document, collection, label = 'Remove From Collection')
    render partial: '/curate/collections/button_remove_from_collection', locals: {
      collection: collection, label: label, document: document
    }
  end

  def available_collections(item = nil)
    if item.present?
      collection_options.reject {|n| n == item}
    else
      collection_options
    end
  end

  private

    def collection_options
      @collection_options ||= current_users_collections
    end

    # Defaults to returning a list of all collections.
    # If you have implement User.collections, the results of that will be used.
    def current_users_collections
      if current_user.respond_to?(:collections)
        current_user.collections.to_a
      else
        Collection.all
      end
    end
end
