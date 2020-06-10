# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    title { ['My Admin Set'] }
  end
end
