module Hyrax
  class AdminSetPresenter < CollectionPresenter
    def total_items
      ActiveFedora::SolrService.count("{!field f=isPartOf_ssim}#{id}", fl: id)
    end
  end
end
