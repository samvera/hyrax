Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record, class: Sufia::Feature
  strategy :default

  # Note, if this is deactivated, a default admin set will be created and all
  # works will be assigned to it when they are created.
  feature :assign_admin_set,
          default: true,
          description: "Ability to assign uploaded items to an admin set"
end
