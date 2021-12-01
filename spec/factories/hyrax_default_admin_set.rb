# frozen_string_literal: true
FactoryBot.define do
  factory :stored_default_admin_set_id, class: Hyrax::DefaultAdministrativeSet do
    id { 1 }
    default_admin_set_id { Hyrax::AdminSetCreateService::DEFAULT_ID }
  end
end
