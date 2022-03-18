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
      edit_users         { [] }
      edit_groups        { [] }
      read_users         { [] }
      members            { nil }
      visibility_setting { nil }
      with_index         { true }
      apply_depositor_permissions { true }
    end

    after(:build) do |work, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: work)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end

      evaluator.edit_users << work.depositor if evaluator.apply_depositor_permissions && work.depositor.present?
      work.permission_manager.edit_groups = evaluator.edit_groups
      work.permission_manager.edit_users  = evaluator.edit_users
      work.permission_manager.read_users  = evaluator.read_users

      work.member_ids = evaluator.members.map(&:id) if evaluator.members
    end

    after(:create) do |work, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: work)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end

      evaluator.edit_users << work.depositor if evaluator.apply_depositor_permissions && work.depositor.present?
      work.permission_manager.edit_groups = evaluator.edit_groups
      work.permission_manager.edit_users  = evaluator.edit_users
      work.permission_manager.read_users  = evaluator.read_users

      work.permission_manager.acl.save

      Hyrax.index_adapter.save(resource: work) if evaluator.with_index
    end

    trait :public do
      transient do
        visibility_setting { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
    end

    trait :with_admin_set do
      transient do
        admin_set { valkyrie_create(:hyrax_admin_set) }
      end

      after(:build) do |work, evaluator|
        work.admin_set_id = evaluator.admin_set&.id
      end
    end

    trait :with_default_admin_set do
      admin_set_id { Hyrax::EnsureWellFormedAdminSetService.call }
    end

    trait :with_member_works do
      transient do
        members do
          # If you set a depositor on the containing work, propogate that into these members
          additional_attributes = {}
          additional_attributes[:depositor] = depositor if depositor
          [valkyrie_create(:hyrax_work, additional_attributes), valkyrie_create(:hyrax_work, additional_attributes)]
        end
      end
    end

    trait :with_member_file_sets do
      transient do
        members do
          # If you set a depositor on the containing work, propogate that into these members
          additional_attributes = {}
          additional_attributes[:depositor] = depositor if depositor
          [valkyrie_create(:hyrax_file_set, additional_attributes), valkyrie_create(:hyrax_file_set, additional_attributes)]
        end
      end
    end

    trait :with_thumbnail do
      thumbnail_id do
        file_set = members.find(&:file_set?) ||
                   valkyrie_create(:hyrax_file_set)
        file_set.id
      end
    end

    trait :with_representative do
      representative_id do
        file_set = members.find(&:file_set?) ||
                   valkyrie_create(:hyrax_file_set)
        file_set.id
      end
    end

    trait :as_collection_member do
      member_of_collection_ids { [valkyrie_create(:hyrax_collection).id] }
    end

    trait :as_member_of_multiple_collections do
      member_of_collection_ids do
        [valkyrie_create(:hyrax_collection).id,
         valkyrie_create(:hyrax_collection).id,
         valkyrie_create(:hyrax_collection).id]
      end
    end

    factory :monograph, class: 'Monograph' do
      factory :comet_in_moominland do
        title { 'Comet in Moominland' }
        creator { 'Tove Jansson' }
        record_info { 'An example monograph with enough metadata fill in required fields.' }
      end

      trait :with_member_works do
        transient do
          members { [valkyrie_create(:monograph), valkyrie_create(:monograph)] }
        end
      end
    end
  end
end
