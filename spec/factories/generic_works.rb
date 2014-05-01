FactoryGirl.define do
  factory :work, class: Worthwhile::GenericWork do

    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    factory :public_generic_work do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :work_with_files do
      after(:build) { |work, evaluator| 2.times { work.generic_files << FactoryGirl.build(:generic_file) }}
    end
  end
end
