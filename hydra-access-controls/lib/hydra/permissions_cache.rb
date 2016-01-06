class Hydra::PermissionsCache < Blacklight::AccessControls::PermissionsCache
  extend Deprecation

  Deprecation.warn Hydra::PermissionsCache, "Hydra::PermissionsCache will be removed in Hydra 10.  Use Blacklight::AccessControls::PermissionsCache instead (from blacklight-access_controls gem)."

end
