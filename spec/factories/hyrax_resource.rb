# frozen_string_literal: true

##
# Use for generic Resources, with Hyrax assumptions.
FactoryBot.define do
  factory :hyrax_resource, class: "Hyrax::Resource" do
    trait :under_embargo do
      association :embargo, factory: :hyrax_embargo
    end

    trait :under_lease do
      association :lease, factory: :hyrax_lease
    end
  end
end
