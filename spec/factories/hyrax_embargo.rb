# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_embargo, class: "Hyrax::Embargo" do
    embargo_release_date      { (Time.zone.today + 10).to_s }
    visibility_after_embargo  { 'open' }
    visibility_during_embargo { 'authenticated' }

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    trait :expired do
      embargo_release_date { Time.zone.today - 1 }
    end
  end
end
