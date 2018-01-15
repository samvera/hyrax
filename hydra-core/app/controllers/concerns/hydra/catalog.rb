module Hydra::Catalog
  extend ActiveSupport::Concern
  include Blacklight::Catalog
  include Blacklight::AccessControls::Catalog

  # This will work for BL 6, but will need to move to SearchService in BL 7
  def search_builder
    Hydra::AccessControls::SearchBuilder.new(self, ability: current_ability)
  end

  # Action-specific enforcement
  # Controller "before" filter for enforcing access controls on show actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_show_permissions(opts={})
    # The "super" method comes from blacklight-access_controls.
    # It will check the read permissions for the record.
    # By default, it will return a Hydra::PermissionsSolrDocument
    # that contains the permissions fields for that record
    # so that you can perform additional permissions checks.
    permissions_doc = super

    if permissions_doc.under_embargo? && !can?(:edit, permissions_doc)
      raise Hydra::AccessDenied.new("This item is under embargo.  You do not have sufficient access privileges to read this document.", :edit, params[:id])
    end

    permissions_doc
  end
end
