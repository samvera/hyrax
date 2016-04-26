FactoryGirl.define do
  factory :operation, class: CurationConcerns::Operation do
    operation_type "Test operation"

    trait :failing do
      status CurationConcerns::Operation::FAILURE
    end

    trait :pending do
      status CurationConcerns::Operation::PENDING
    end

    trait :successful do
      status CurationConcerns::Operation::SUCCESS
    end

    factory :batch_create_operation, class: Sufia::BatchCreateOperation do
      operation_type "Batch Create"
    end
  end
end
