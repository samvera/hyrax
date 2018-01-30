module Hyrax
  class AdminSetPresenter < CollectionPresenter
    def total_items
      ActiveFedora::SolrService.count("{!field f=isPartOf_ssim}#{id}")
    end

    def total_viewable_items
      ActiveFedora::Base.where("isPartOf_ssim:#{id}").accessible_by(current_ability).count
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

    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_or_create_admin_set_type
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.admin_admin_set_path(id)
    end
  end
end
