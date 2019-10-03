# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks Works in valkyrie.
FactoryBot.define do
  factory :hyrax_work, class: 'Hyrax::Test::SimpleWork' do
    trait :under_embargo do
      association :embargo, factory: :hyrax_embargo
    end

    trait :under_lease do
      association :lease, factory: :hyrax_lease
    end

    transient do
      visibility_setting { nil }
    end

    after(:build) do |work, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: work)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end
    end

    after(:create) do |work, evaluator|
      if evaluator.visibility_setting
        writer = Hyrax::VisibilityWriter.new(resource: work)
        writer.assign_access_for(visibility: evaluator.visibility_setting)
        writer.permission_manager.acl.save
      end
    end

    trait :public do
      transient do
        visibility_setting { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
    end
  end
end
