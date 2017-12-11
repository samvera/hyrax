module Hyrax
  class AdminSetPresenter < CollectionPresenter
    def total_items
      solr = Valkyrie::MetadataAdapter.find(:index_solr).connection
      results = solr.get('select', params: { q: "{!field f=admin_set_id_ssim}id-#{id}",
                                             rows: 0,
                                             qt: 'standard' })
      results['response']['numFound'].to_i
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
