# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    title { ['My Admin Set'] }
  end

  factory :invalid_hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    # Title is required.  Without title, the admin set is invalid.
  end

  factory :default_hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    id { Hyrax::AdminSetCreateService::DEFAULT_ID }
    title { Hyrax::AdminSetCreateService::DEFAULT_TITLE }
  end
end
