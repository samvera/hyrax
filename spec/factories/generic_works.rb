FactoryBot.define do
  factory :work, class: GenericWork do
    to_create do |instance|
      persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      persister.save(resource: instance)
    end

    transient do
      user { FactoryBot.create(:user) }
      # Set to true (or a hash) if you want to create an admin set
      with_admin_set false
    end

    # It is reasonable to assume that a work has an admin set; However, we don't want to
    # go through the entire rigors of creating that admin set.
    before(:create) do |work, evaluator|
      if evaluator.with_admin_set
        attributes = {}
        attributes[:id] = work.admin_set_id if work.admin_set_id.present?
        attributes = evaluator.with_admin_set.merge(attributes) if evaluator.with_admin_set.respond_to?(:merge)
        admin_set = create_for_repository(:admin_set, attributes)
        work.admin_set_id = admin_set.id
      end
    end

    title ["Test title"]
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    trait :private do
      # the work is private by default. This is just an optional annotation.
    end

    trait :public do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :registered_generic_work do
      read_groups ["registered"]
    end

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.member_ids += [create_for_repository(:file_set, user: evaluator.user, title: ['A Contained FileSet'], label: 'filename.pdf').id]
      end
    end

    factory :work_with_files do
      before(:create) do |work, evaluator|
        2.times { work.member_ids += [create_for_repository(:file_set, user: evaluator.user).id] }
      end
    end

    factory :work_with_ordered_files do
      before(:create) do |work, evaluator|
        $stderr.warn "work_with_ordered_files is deprecated. Use work_with_one_file instead"
        work.member_ids += [create_for_repository(:file_set, user: evaluator.user).id]
      end
    end

    factory :work_with_one_child do
      before(:create) do |work, evaluator|
        work.member_ids += [create_for_repository(:work, user: evaluator.user, title: ['A Contained Work']).id]
      end
    end

    factory :work_with_two_children do
      before(:create) do |work, evaluator|
        work.member_ids += [create_for_repository(:work, user: evaluator.user, title: ['A Contained Work'], id: "BlahBlah1").id]
        work.member_ids += [create_for_repository(:work, user: evaluator.user, title: ['Another Contained Work'], id: "BlahBlah2").id]
      end
    end

    factory :work_with_representative_file do
      before(:create) do |work, evaluator|
        work.member_ids += [create_for_repository(:file_set, user: evaluator.user, title: ['A Contained FileSet']).id]
        work.representative_id = work.member_ids[0]
      end
    end

    factory :work_with_file_and_work do
      before(:create) do |work, evaluator|
        work.member_ids += [create_for_repository(:file_set, user: evaluator.user).id]
        work.member_ids += [create_for_repository(:work, user: evaluator.user).id]
      end
    end

    factory :with_embargo_date do
      transient do
        embargo_date { Date.tomorrow.to_s }
        current_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
        future_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
      factory :embargoed_work do
        after(:build) { |work, evaluator| work.apply_embargo(evaluator.embargo_date, evaluator.current_state, evaluator.future_state) }
      end
      factory :embargoed_work_with_files do
        after(:build) { |work, evaluator| work.apply_embargo(evaluator.embargo_date, evaluator.current_state, evaluator.future_state) }
        after(:create) do |work, evaluator|
          2.times { work.member_ids += [create_for_repository(:file_set, user: evaluator.user).id] }
        end
      end
    end

    factory :with_lease_date do
      transient do
        lease_date { Date.tomorrow.to_s }
        current_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        future_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      end
      factory :leased_work do
        after(:build) { |work, evaluator| work.apply_lease(evaluator.lease_date, evaluator.current_state, evaluator.future_state) }
      end
      factory :leased_work_with_files do
        after(:build) { |work, evaluator| work.apply_lease(evaluator.lease_date, evaluator.current_state, evaluator.future_state) }
        after(:create) do |work, evaluator|
          2.times { work.member_ids += [create_for_repository(:file_set, user: evaluator.user).id] }
        end
      end
    end
  end

  # Doesn't set up any edit_users
  factory :work_without_access, class: GenericWork do
    to_create do |instance|
      persister = Valkyrie.config.metadata_adapter.persister
      persister.save(resource: instance)
    end

    title ['Test title']
    depositor { FactoryBot.create(:user).user_key }
  end
end
