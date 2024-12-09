# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_lease, class: "Hyrax::Lease" do
    lease_expiration_date   { (Time.zone.today + 10).to_datetime }
    visibility_after_lease  { 'authenticated' }
    visibility_during_lease { 'open' }

    after(:build) do |lease, evaluator|
      lease.lease_expiration_date = evaluator.lease_expiration_date.to_datetime
    end

    to_create do |instance|
      saved_instance = Valkyrie.config.metadata_adapter.persister.save(resource: instance)
      instance.id = saved_instance.id
      saved_instance
    end

    trait :expired do
      lease_expiration_date { (Time.zone.today - 2).to_datetime }
    end
  end
end
