# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_resource, class: "Hyrax::Resource" do
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    trait :under_embargo do
      association :embargo, factory: :hyrax_embargo
    end
  end
end
