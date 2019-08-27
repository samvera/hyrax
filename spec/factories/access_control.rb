# frozen_string_literal: true
FactoryBot.define do
  factory :access_control, class: Hyrax::AccessControl do
    permissions { build(:permission) }

    trait :with_target do
      access_to { valkyrie_create(:hyrax_resource).id }

      permissions { build(:permission, access_to: access_to) }
    end
  end
end
