FactoryGirl.define do
  factory :work, aliases: [:generic_work, :private_generic_work], class: GenericWork do
    transient do
      user { FactoryGirl.create(:user) }
      embargo_date { Date.tomorrow.to_s }
    end

    title ["Test title"]
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    before(:create) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end


    factory :public_generic_work, aliases: [:public_work] do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :work_with_one_file do
      after(:create) { |work, evaluator| Hydra::Works::AddGenericFileToGenericWork.call(work, FactoryGirl.create(:generic_file, user: evaluator.user, title:['A Contained Generic File'], filename:['filename.pdf'])) }
    end

    factory :work_with_files do
      after(:create) { |work, evaluator| 2.times { Hydra::Works::AddGenericFileToGenericWork.call(work, FactoryGirl.create(:generic_file, user: evaluator.user)) } }
    end
  end
end
