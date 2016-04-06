# View Helpers for Hydra Batch Edit functionality
module BatchSelectHelper
  # determines if the given document id is in the batch
  # def item_in_batch?(doc_id)
  #   session[:batch_document_ids] && session[:batch_document_ids].include?(doc_id) ? true : false
  # end

  # Displays the batch edit tools.  Put this in your search result page template.  We recommend putting it in catalog/_sort_and_per_page.html.erb
  def batch_select_tools
    render partial: '/batch_select/tools'
  end

  # Displays the button to select/deselect items for your batch.  Call this in the index partial that's rendered for each search result.
  # @param [Hash] document the Hash (aka Solr hit) for one Solr document
  def button_for_add_to_batch(document)
    render partial: '/batch_select/add_button', locals: { document: document }
  end

  # Displays the check all button to select/deselect items for your batch.  Put this in your search result page template.  We put it in catalog/index.html
  def batch_check_all(label = 'Use all results')
    render partial: '/batch_select/check_all', locals: { label: label }
  end
end
