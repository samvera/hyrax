FactoryGirl.define do
  factory :permission_template, class: Hyrax::PermissionTemplate do
    admin_set_id '88888'

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
