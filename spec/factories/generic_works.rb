FactoryGirl.define do
  factory :work, aliases: [:generic_work, :private_generic_work], class: Sufia::Works::GenericWork do
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

    factory :work_with_files do
      after(:build) { |work, _| 2.times { work.generic_files << FactoryGirl.create(:generic_file) }}
    end
  end
end
