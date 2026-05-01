# frozen_string_literal: true
FactoryBot.define do
  factory :hyrax_redirect, class: "Hyrax::Redirect" do
    sequence(:path) { |n| "/legacy/#{n}" }
    canonical { false }

    trait :canonical do
      canonical { true }
    end
  end
end
