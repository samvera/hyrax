# frozen_string_literal: true

FactoryBot.define do
  factory :work, aliases: [:generic_work, :private_generic_work], class: 'GenericWork' do
    transient do
      user { FactoryBot.create(:user) }
      # Set to true (or a hash) if you want to create an admin set
      with_admin_set { false }
    end

    # It is reasonable to assume that a work has an admin set; However, we don't want to
    # go through the entire rigors of creating that admin set.
    before(:create) do |work, evaluator|
      if evaluator.with_admin_set
        attributes = {}
        attributes[:id] = work.admin_set_id if work.admin_set_id.present?
        attributes = evaluator.with_admin_set.merge(attributes) if evaluator.with_admin_set.respond_to?(:merge)
        admin_set = create(:admin_set, attributes)
        work.admin_set_id = admin_set.id
      end
    end

    after(:create) do |work, _evaluator|
      work.save! if work.try(:member_of_collections) && work.member_of_collections.present?
    end

    title { ["Test title"] }

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key) if work.try(:apply_depositor_metadata, evaluator.user.user_key)
    end

    factory :public_generic_work, aliases: [:public_work], traits: [:public]

    trait :public do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    factory :invalid_generic_work do
      title { nil }
    end

    factory :private_work do
      # private is default
      # visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end

    factory :registered_generic_work do
      read_groups { ["registered"] }
    end

    factory :work_with_one_file do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user, title: ['A Contained FileSet'], label: 'filename.pdf')
      end
    end

    factory :work_with_files do
      before(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, user: evaluator.user) } }
    end

    factory :work_with_image_files do
      before(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, :image, user: evaluator.user) } }
    end

    factory :work_with_ordered_files do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user)
        work.ordered_member_proxies.insert_target_at(0, create(:file_set, user: evaluator.user))
      end
    end

    factory :work_with_one_child do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:work, user: evaluator.user, title: ['A Contained Work'])
      end
    end

    factory :work_with_two_children do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:work, user: evaluator.user, title: ['A Contained Work'], id: "BlahBlah1")
        work.ordered_members << create(:work, user: evaluator.user, title: ['Another Contained Work'], id: "BlahBlah2")
      end
    end

    factory :work_with_representative_file do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user, title: ['A Contained FileSet'])
        work.representative_id = work.members[0].id
      end
    end

    factory :work_with_file_and_work do
      before(:create) do |work, evaluator|
        work.ordered_members << create(:file_set, user: evaluator.user)
        work.ordered_members << create(:work, user: evaluator.user)
      end
    end

    factory :with_embargo_date do
      # build with defaults:
      # let(:work) { create(:embargoed_work) }

      # build with specific values:
      # let(:embargo_attributes) do
      #   { embargo_date: Date.tomorrow.to_s,
      #     current_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      #     future_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      # end
      # let(:work) { create(:embargoed_work, with_embargo_attributes: embargo_attributes) }

      transient do
        with_embargo_attributes { false }
        embargo_date { Date.tomorrow.to_s }
        current_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
        future_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
      factory :embargoed_work do
        after(:build) do |work, evaluator|
          if evaluator.with_embargo_attributes
            work.apply_embargo(evaluator.with_embargo_attributes[:embargo_date],
                               evaluator.with_embargo_attributes[:current_state],
                               evaluator.with_embargo_attributes[:future_state])
          else
            work.apply_embargo(evaluator.embargo_date,
                               evaluator.current_state,
                               evaluator.future_state)
          end
        end
      end
      factory :embargoed_work_with_files do
        after(:build) do |work, evaluator|
          if evaluator.with_embargo_attributes
            work.apply_embargo(evaluator.with_embargo_attributes[:embargo_date],
                               evaluator.with_embargo_attributes[:current_state],
                               evaluator.with_embargo_attributes[:future_state])
          else
            work.apply_embargo(evaluator.embargo_date,
                               evaluator.current_state,
                               evaluator.future_state)
          end
        end
        after(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, user: evaluator.user) } }
      end
    end

    factory :with_lease_date do
      # build with defaults:
      # let(:work) { create(:leased_work) }

      # build with specific values:
      # let(:lease_attributes) do
      #   { lease_date: Date.tomorrow.to_s,
      #     current_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      #     future_state: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      # end
      # let(:work) { create(:leased_work, with_lease_attributes: lease_attributes) }

      transient do
        with_lease_attributes { false }
        lease_date { Date.tomorrow.to_s }
        current_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        future_state { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      end
      factory :leased_work do
        after(:build) do |work, evaluator|
          if evaluator.with_lease_attributes
            work.apply_lease(evaluator.with_lease_attributes[:lease_date],
                             evaluator.with_lease_attributes[:current_state],
                             evaluator.with_lease_attributes[:future_state])
          else
            work.apply_lease(evaluator.lease_date,
                             evaluator.current_state,
                             evaluator.future_state)
          end
        end
      end
      factory :leased_work_with_files do
        after(:build) do |work, evaluator|
          if evaluator.with_lease_attributes
            work.apply_lease(evaluator.with_lease_attributes[:lease_date],
                             evaluator.with_lease_attributes[:current_state],
                             evaluator.with_lease_attributes[:future_state])
          else
            work.apply_lease(evaluator.lease_date,
                             evaluator.current_state,
                             evaluator.future_state)
          end
        end
        after(:create) { |work, evaluator| 2.times { work.ordered_members << create(:file_set, user: evaluator.user) } }
      end
    end
  end

  # Doesn't set up any edit_users
  factory :work_without_access, class: 'GenericWork' do
    title { ['Test title'] }
    depositor { create(:user).user_key }
  end
end
