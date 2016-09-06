FactoryGirl.define do
  factory :work, aliases: [:generic_work, :private_generic_work], class: GenericWork do
    transient do
      user { FactoryGirl.create(:user) }
    end

    title ["Test title"]
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    factory :public_generic_work, aliases: [:public_work], traits: [:public]

    trait :public do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :registered_generic_work do
      read_groups ["registered"]
    end

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user, title: ['A Contained FileSet'], label: 'filename.pdf')
      end
    end
  end
end
