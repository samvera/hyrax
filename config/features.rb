Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record, class: Hyrax::Feature
  strategy :default

  feature :proxy_deposit,
          default: true,
          description: "Depositors may designate proxies to deposit works on their behalf"

  feature :transfer_works,
          default: true,
          description: "Depositors may transfer their works to another user"

  feature :assign_admin_set,
          default: true,
          description: "Ability to assign uploaded items to an admin set"
end
