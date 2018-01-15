module Hydra
  module AccessControls
    class SearchBuilder < Blacklight::AccessControls::SearchBuilder
      # Find the name of the solr field for this type of permission.
      # e.g. "read_access_group_ssim" or "discover_access_person_ssim".
      # Used by blacklight-access_controls.
      def solr_field_for(permission_type, permission_category)
        permissions = Hydra.config.permissions[permission_type.to_sym]
        permission_category == 'group' ? permissions.group : permissions.individual
      end
    end
  end
end
