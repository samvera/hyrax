# View Helpers for Hydra Collections functionality
module Curate::CollectionsHelper

  def button_for_remove_item_from_collection(document, collection, label = 'Remove From Collection')
    render partial: '/curate/collections/button_remove_from_collection', locals: {
      collection: collection, label: label, document: document
    }
  end

end
