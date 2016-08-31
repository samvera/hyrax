Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record, class: Sufia::Feature
  strategy :default

  feature :assign_admin_set,
          default: true,
          description: "Ability to assign uploaded items to an admin set"
end
