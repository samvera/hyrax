FactoryGirl.define do
  factory :permission_template, class: Hyrax::PermissionTemplate do
    # Given that there is a one to one strong relation between permission_template and admin_set,
    # with a unique index on the admin_set_id, I don't want to have duplication in admin_set_id
    sequence(:admin_set_id) { |n| format("%010d", n) }

    before(:create) do |permission_template, evaluator|
      if evaluator.with_admin_set
        admin_set_id = permission_template.admin_set_id
        admin_set =
          if admin_set_id.present?
            begin
              AdminSet.find(admin_set_id)
            rescue
              create(:admin_set, id: admin_set_id)
            end
          else
            create(:admin_set)
          end
        permission_template.admin_set_id = admin_set.id
      end
    end

    transient do
      with_admin_set false
    end
  end
end
