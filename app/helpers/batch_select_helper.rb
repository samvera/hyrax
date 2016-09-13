# View Helpers for Hydra Batch Edit functionality
module BatchSelectHelper
  # Displays the button to select/deselect items for your batch.  Call this in the index partial that's rendered for each search result.
  # @param [Hash] document the Hash (aka Solr hit) for one Solr document
  def button_for_add_to_batch(document)
    render partial: '/batch_select/add_button', locals: { document: document }
  end
end
