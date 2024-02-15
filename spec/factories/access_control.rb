# frozen_string_literal: true
FactoryBot.define do
  factory :access_control, class: Hyrax::AccessControl do
    permissions { build(Hyrax::Specs::FactoryName.permission) }

    trait :with_target do
      access_to { valkyrie_create(Hyrax::Specs::FactoryName.hyrax_resource).id }

      permissions { build(Hyrax::Specs::FactoryName.permission, access_to: access_to) }
    end
  end
end
