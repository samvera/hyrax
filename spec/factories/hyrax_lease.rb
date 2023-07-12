# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_lease, class: "Hyrax::Lease" do
    lease_expiration_date   { (Time.zone.today + 10).to_s }
    visibility_after_lease  { 'authenticated' }
    visibility_during_lease { 'open' }

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    trait :expired do
      lease_expiration_date { Time.zone.today - 1 }
    end
  end
end
