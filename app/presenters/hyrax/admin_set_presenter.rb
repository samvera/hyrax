module Hyrax
  class AdminSetPresenter < CollectionPresenter
    def total_items
      ActiveFedora::SolrService.count("{!field f=isPartOf_ssim}#{id}")
    end

    # AdminSet cannot be deleted if default set or non-empty
    def disable_delete?
      AdminSet.default_set?(id) || total_items > 0
    end

    # Message to display if deletion is disabled
    def disabled_message
      return I18n.t('hyrax.admin.admin_sets.delete.error_default_set') if AdminSet.default_set?(id)
      return I18n.t('hyrax.admin.admin_sets.delete.error_not_empty') if total_items > 0
    end
  end
end
