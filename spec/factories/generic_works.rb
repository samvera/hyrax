FactoryGirl.define do
  factory :work, aliases: [:generic_work, :private_generic_work], class: GenericWork do
    ignore do
      user { FactoryGirl.create(:user) }
    end

    title ["Test title"]
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    before(:create) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end


    factory :public_generic_work do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :work_with_files do
      after(:build) { |work, _| 2.times { work.generic_files << FactoryGirl.build(:generic_file) }}
    end

    factory :embargoed_work do
      after(:build) { |work, _| work.apply_embargo(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
    end

    factory :embargoed_work_with_files do
      after(:build) { |work, _| 2.times { work.generic_files << FactoryGirl.build(:generic_file) }}
      after(:build) { |work, _| work.apply_embargo(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
    end

    factory :leased_work_with_files do
      after(:build) { |work, _| 2.times { work.generic_files << FactoryGirl.build(:generic_file) }}
      after(:build) { |work, _| work.apply_lease(Date.tomorrow.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE) }
    end
  end
end
