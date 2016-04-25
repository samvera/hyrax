FactoryGirl.define do
  factory :operation, class: CurationConcerns::Operation do
    operation_type "Test batch operation"

    trait :failing do
      status CurationConcerns::Operation::FAILURE
    end

    trait :pending do
      status CurationConcerns::Operation::PENDING
    end

    trait :successful do
      status CurationConcerns::Operation::SUCCESS
    end
  end
end
