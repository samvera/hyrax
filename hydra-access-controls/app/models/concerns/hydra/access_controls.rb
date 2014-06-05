module Hydra
  module AccessControls
    extend ActiveSupport::Autoload
    autoload :AccessRight
    autoload :WithAccessRight
    autoload :Embargoable
    autoload :Visibility
    autoload :Permission
    autoload :Permissions
  end
end
