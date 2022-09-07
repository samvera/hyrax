# frozen_string_literal: true
module Hyrax
  class AdminSetPresenter < CollectionPresenter
    ##
    # @return [Boolean] true if there are items
    def any_items?
      total_items.positive?
    end

    def total_items
      Hyrax::SolrService.count("{!field f=#{Hyrax.config.admin_set_predicate.qname.last}_ssim}#{id}")
    end

    def total_viewable_items
      field_pairs = { "#{Hyrax.config.admin_set_predicate.qname.last}_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .accessible_by(ability: current_ability)
                      .count
    end

    # AdminSet cannot be deleted if default set or non-empty
    def disable_delete?
      default_set? || any_items?
    end

    # Message to display if deletion is disabled
    def disabled_message
      return I18n.t('hyrax.admin.admin_sets.delete.error_default_set') if default_set?
      I18n.t('hyrax.admin.admin_sets.delete.error_not_empty') if any_items?
    end

    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_or_create_admin_set_type
    end

    # Overrides delegate because admin sets do not index collection type gid
    def collection_type_gid
      collection_type.to_global_id
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.admin_admin_set_path(id, locale: I18n.locale)
    end

    def available_parent_collections(*)
      []
    end

    # For the Managed Collections tab, determine the label to use for the level of access the user has for this admin set.
    # Checks from most permissive to most restrictive.
    # @return String the access label (e.g. Manage, Deposit, View)
    def managed_access
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.manage') if current_ability.can?(:edit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.deposit') if current_ability.can?(:deposit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.view') if current_ability.can?(:read, solr_document)
      ''
    end

    # Determine if the user can perform batch operations on this admin set.  Currently, the only
    # batch operation allowed is deleting, so this is equivalent to checking if the user can delete
    # the admin set determined by criteria...
    # * user must be able to edit the admin set to be able to delete it
    # * the admin set itself must be able to be deleted (i.e., there cannot be any works in the admin set)
    # @return Boolean true if the user can perform batch actions; otherwise, false
    def allow_batch?
      return false unless current_ability.can?(:edit, solr_document)
      !disable_delete?
    end

    private

    def default_set?
      Hyrax::AdminSetCreateService.default_admin_set?(id: id)
    end
  end
end
