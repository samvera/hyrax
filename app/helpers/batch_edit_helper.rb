# View Helpers for Hydra Batch Edit functionality
module BatchEditHelper
  # determines if the given document id is in the batch
  def item_in_batch?(doc_id)
    session[:batch_document_ids] && session[:batch_document_ids].include?(doc_id) ? true : false
  end

  # Returns true if user has activated batch edit mode in session
  def batch_edit_state
    session[:batch_edit_state] ||= 'off'
  end

  # Displays the batch edit tools.  Put this in your search result page template.  We recommend putting it in catalog/_sort_and_per_page.html.erb
  def batch_edit_tools
    render partial: '/batch_edits/tools'
  end

  # Displays the button that users click when they are done selecting items for a batch.  Put this in your search result page template.  We put it in catalog/index.html
  def batch_edit_continue(label = 'Update Selected')
    render partial: '/batch_edits/next_page', locals: { label: label }
  end

  # Displays the button to select/deselect items for your batch.  Call this in the index partial that's rendered for each search result.
  # @param [Hash] document the Hash (aka Solr hit) for one Solr document
  def batch_edit_select(document)
    button_for_add_to_batch document
  end

  # Displays the check all button to select/deselect items for your batch.  Put this in your search result page template.  We put it in catalog/index.html
  def batch_check_all(label = 'Use all results')
    render partial: '/batch_edits/check_all', locals: { label: label }
  end

  # Displays the button that users click when they are done selecting items for a batch to Remove those items from the repository.  Put this in your search result page template.  We put it in catalog/index.html
  def batch_edit_delete_batch(label = 'Delete Selected', confirm = 'Are you sure?')
    render partial: '/batch_edits/delete_batch', locals: { label: label, confirm: confirm }
  end
end
