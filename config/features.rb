# frozen_string_literal: true
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
          default: false,
          description: "Enable uploading batches of works"

  feature :hide_private_items,
          default: false,
          description: "Do not show the private items."

  feature :hide_users_list,
          default: true,
          description: "Do not show users list unless user has authenticated."

  feature :cache_work_iiif_manifest,
          default: false,
          description: "Use Rails.cache to cache the JSON document for IIIF manifests"
  feature :read_only,
          default: false,
          description: "Put the system into read-only mode. Deposits, edits, approvals and anything that makes a change to the data will be disabled."
rescue Flipflop::StrategyError, Flipflop::FeatureError => err
  Hyrax.logger.warn "Ignoring #{err}: #{err.message}"
end
