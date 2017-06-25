module Hydra::AccessControlsEnforcement
  extend ActiveSupport::Concern
  include Blacklight::AccessControls::Enforcement

  included do
    Deprecation.warn(self, 'Hydra::AccessControlsEnforcement is deprecated ' \
      'and will be removed in version 11. Use ' \
      'Hydra::AccessControls::SearchBuilder instead.')
  end

  protected

  def under_embargo?
    load_permissions_from_solr
    embargo_key = Hydra.config.permissions.embargo.release_date
    if @permissions_solr_document[embargo_key]
      embargo_date = Date.parse(@permissions_solr_document[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end

  # Which permission levels (logical OR) will grant you the ability to discover documents in a search.
  # Overrides blacklight-access_controls method.
  def discovery_permissions
    @discovery_permissions ||= ["edit","discover","read"]
  end

  # Find the name of the solr field for this type of permission.
  # e.g. "read_access_group_ssim" or "discover_access_person_ssim".
  # Used by blacklight-access_controls.
  def solr_field_for(permission_type, permission_category)
    permissions = Hydra.config.permissions[permission_type.to_sym]
    permission_category == 'group' ? permissions.group : permissions.individual
  end

end
