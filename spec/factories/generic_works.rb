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

    factory :work_with_files do
      before(:create) { |work, evaluator| 2.times { work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user) } }
    end

    factory :work_with_ordered_files do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user)
        work.ordered_member_proxies.insert_target_at(0, FactoryGirl.create(:file_set, user: evaluator.user))
      end
    end

    factory :work_with_one_child do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:generic_work, user: evaluator.user, title: ['A Contained Work'])
      end
    end

    factory :work_with_two_children do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:generic_work, user: evaluator.user, title: ['A Contained Work'], id: "BlahBlah1")
        work.ordered_members << FactoryGirl.create(:generic_work, user: evaluator.user, title: ['Another Contained Work'], id: "BlahBlah2")
      end
    end

    factory :work_with_representative_file do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user, title: ['A Contained FileSet'])
        work.representative_id = work.members[0].id
      end
    end

    factory :work_with_file_and_work do
      before(:create) do |work, evaluator|
        work.ordered_members << FactoryGirl.create(:file_set, user: evaluator.user)
        work.ordered_members << FactoryGirl.create(:generic_work, user: evaluator.user)
      end
    end
  end

  # Doesn't set up any edit_users
  factory :work_without_access, class: GenericWork do
    title ['Test title']
    depositor { FactoryGirl.create(:user).user_key }
  end
end
