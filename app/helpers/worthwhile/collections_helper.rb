# Mostly methods copied over from Sufia when we pulled in it's Collections implementation
module Worthwhile::CollectionsHelper
  def has_collection_search_parameters?
    !params[:cq].blank?
  end
end