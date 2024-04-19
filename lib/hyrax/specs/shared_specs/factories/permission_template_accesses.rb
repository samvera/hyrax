# frozen_string_literal: true
FactoryBot.define do
  factory :permission_template_access, class: Hyrax::PermissionTemplateAccess do
    permission_template
    trait :manage do
      access { 'manage' }
    end

    trait :deposit do
      access { 'deposit' }
    end

    trait :view do
      access { 'view' }
    end
  end
end
