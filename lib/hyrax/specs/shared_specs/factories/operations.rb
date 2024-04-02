# frozen_string_literal: true
FactoryBot.define do
  factory :operation, class: Hyrax::Operation do
    operation_type { "Test operation" }

    trait :failing do
      status { Hyrax::Operation::FAILURE }
    end

    trait :pending do
      status { Hyrax::Operation::PENDING }
    end

    trait :successful do
      status { Hyrax::Operation::SUCCESS }
    end

    factory :batch_create_operation, class: Hyrax::BatchCreateOperation do
      operation_type { "Batch Create" }
    end
  end
end
