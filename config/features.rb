Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record, class: Hyrax::Feature
  strategy Hyrax::Strategies::YamlStrategy, config: Hyrax.config.feature_config_path
  strategy :default

  feature :proxy_deposit,
          default: true,
          description: "Depositors may designate proxies to deposit works on their behalf"

  feature :transfer_works,
          default: true,
          description: "Depositors may transfer their works to another user"

  # Note, if this is deactivated, a default admin set will be created and all
  # works will be assigned to it when they are created.
  feature :assign_admin_set,
          default: true,
          description: "Ability to assign uploaded items to an admin set"
end
