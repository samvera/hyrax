FactoryGirl.define do
  factory :operation, class: Sufia::Operation do
    operation_type "Test operation"

    trait :failing do
      status Sufia::Operation::FAILURE
    end

    trait :pending do
      status Sufia::Operation::PENDING
    end

    trait :successful do
      status Sufia::Operation::SUCCESS
    end

    factory :batch_create_operation, class: Sufia::BatchCreateOperation do
      operation_type "Batch Create"
    end
  end
end
