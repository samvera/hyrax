FactoryGirl.define do
  factory :work, class: Worthwhile::GenericWork do

    factory :work_with_files do
      after(:build) { |work, evaluator| 2.times { work.generic_files << FactoryGirl.build(:generic_file) }}
    end
  end
end
