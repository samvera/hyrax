FactoryGirl.define do
  # The ::GenericWork model is defined in spec/internal/app/models by the
  # curation_concerns:install generator.
  factory :generic_work, aliases: [:work, :private_generic_work], class: GenericWork do
    transient do
      user { FactoryGirl.create(:user) }
    end

    title ['Test title']
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    factory :public_generic_work do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user, title: ['A Contained Generic File'], filename: 'filename.pdf')
      end
    end

    factory :work_with_files do
      before(:create) { |work, evaluator| 2.times { work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user) } }
    end

    factory :with_embargo_date do
      transient do
        embargo_date { Date.tomorrow.to_s }
      end
      factory :embargoed_work do
        after(:build) { |work, evaluator| work.apply_embargo(evaluator.embargo_date, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
      end

      factory :embargoed_work_with_files do
        after(:build) { |work, evaluator| work.apply_embargo(evaluator.embargo_date, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
        after(:create) { |work, evaluator| 2.times { work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user) } }
      end

      factory :leased_work do
        after(:build) { |work, evaluator| work.apply_lease(evaluator.embargo_date, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE) }
      end

      factory :leased_work_with_files do
        after(:build) { |work, evaluator| work.apply_lease(evaluator.embargo_date, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE) }
        after(:create) { |work, evaluator| 2.times { work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user) } }
      end
    end
  end
end
