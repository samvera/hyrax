# frozen_string_literal: true

##
# Use for generic Resources, with Hyrax assumptions.
FactoryBot.define do
  factory :hyrax_resource, class: "Hyrax::Resource" do
    trait :under_embargo do
      embargo_id { FactoryBot.create(Hyrax::Specs::FactoryName.hyrax_embargo).id }
    end

    trait :under_lease do
      lease_id { FactoryBot.create(Hyrax::Specs::FactoryName.hyrax_lease).id }
    end
  end
end
