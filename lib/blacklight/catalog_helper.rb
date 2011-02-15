# Note: not sure we're still using this in hydrangea...
# This is a replica of some methods that are in Blacklight's CatalogController that we wanted to re-use in other controllers
module Blacklight::CatalogHelper
 
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