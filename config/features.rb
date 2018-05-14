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

  feature :show_deposit_agreement,
          default: true,
          description: "Show a deposit agreement to users creating works"

  feature :active_deposit_agreement_acceptance,
          default: Hyrax.config.active_deposit_agreement_acceptance?,
          description: "Require an active acceptance of the deposit agreement by checking a checkbox"

  feature :batch_upload,
          default: true,
          description: "Enable uploading batches of works"

  feature :analytics_redesign,
          default: false,
          description: "Display new reporting features. *Very Experimental*"

  feature :hide_private_items,
          default: false,
          description: "Do not show the private items."
end
