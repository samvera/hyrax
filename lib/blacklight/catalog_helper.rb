# Note: not sure we're still using this in hydrangea...
# This is a replica of some methods that are in Blacklight's CatalogController that we wanted to re-use in other controllers
module Blacklight::CatalogHelper
  # calls setup_previous_document then setup_next_document.
  # used in the show action for single view pagination.
  def setup_next_and_previous_documents
    setup_previous_document
    setup_next_document
  end

  # gets a document based on its position within a resultset  
  def setup_document_by_counter(counter)
    return if counter < 1 || session[:search].blank?
    # need to duplicate search session hash so we aren't modifying the original (and don't get the qt in the Back to search results link)
    search = session[:search].dup || {}
    # enforcing search restrictions
    # if the user is not a reader then use the pulic qt, otherwise use the default qt (using logic from enforce_search_permissions method)
    if !reader?
      search[:qt] = Blacklight.config[:public_qt]
    end
    get_single_doc_via_search(search.merge({:page => counter}))
  end

  def setup_previous_document
    @previous_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i - 1) : nil
  end

  def setup_next_document
    @next_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i + 1) : nil
  end

  # sets up the session[:search] hash if it doesn't already exist
  def search_session
    session[:search] ||= {}
  end
  
  # sets up the session[:history] hash if it doesn't already exist.
  # assigns all Search objects (that match the searches in session[:history]) to a variable @searches.
  def history_session
    session[:history] ||= []
    @searches = searches_from_history # <- in ApplicationController
  end
  
end