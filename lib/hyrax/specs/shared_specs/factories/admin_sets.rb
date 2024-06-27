# frozen_string_literal: true
FactoryBot.define do
  factory :admin_set do
    sequence(:title) { |n| ["Title #{n}"] }

    # Given the relationship between permission template and admin set, when
    # an admin set is created via a factory, I believe it is appropriate to go ahead and
    # create the corresponding permission template
    #
    # This way, we can go ahead
    after(:create) do |admin_set, evaluator|
      if evaluator.with_permission_template
        attributes = { source_id: admin_set.id }
        attributes = evaluator.permission_template_attributes.merge(attributes) if evaluator.permission_template_attributes.respond_to?(:merge)
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        # There is a unique constraint on permission_templates.source_id; I don't want to
        # create a permission template if one already exists for this admin_set
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: admin_set.id)
      end
    end

    transient do
      # false, true, or Hash with keys for permission_template
      with_permission_template { false }
      permission_template_attributes { {} }
    end

    factory :complete_admin_set do
      alternative_title { ['alternative admin set title'] }
      creator           { ['moomin', 'snufkin'] }
      description       { ['Before a revolution happens', 'it is perceived as impossible'] }
    end
  end
end
