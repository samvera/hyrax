# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks Works in valkyrie.
FactoryBot.define do
  factory :hyrax_work, class: 'Hyrax::Test::SimpleWork' do
    trait :under_embargo do
      association :embargo, factory: :hyrax_embargo

      after(:create) do |work, _e|
        Hyrax::EmbargoManager.new(resource: work).apply
        work.permission_manager.acl.save
      end
    end

    trait :with_expired_enforced_embargo do
      after(:build) do |work, _evaluator|
        work.embargo = FactoryBot.valkyrie_create(:hyrax_embargo, :expired)
      end

      after(:create) do |work, _evaluator|
        allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(10.days.ago)
        Hyrax::EmbargoManager.new(resource: work).apply
        allow(Hyrax::TimeService).to receive(:time_in_utc).and_call_original

        work.permission_manager.acl.save
      end
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
      uploaded_files { [] }
    end

    after(:build) do |work, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: work)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end

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
      if evaluator.uploaded_files.present?
        Hyrax::WorkUploadsHandler.new(work: work).add(files: evaluator.uploaded_files).attach
        # Sometimes ValkyrieIngestJob is allowed to run by the test, so don't
        # re-run it.
        if Hyrax.query_service.find_by(id: work.id).member_ids.empty?
          evaluator.uploaded_files.each do |file|
            allow(Hyrax.config.characterization_service).to receive(:run).and_return(true)
            # I don't love this - we might want to just run background jobs so
            # this is more real, but we'd have to stub some things.
            ValkyrieIngestJob.perform_now(file)
          end
        end
      end

      work.permission_manager.edit_groups = evaluator.edit_groups
      work.permission_manager.edit_users  = evaluator.edit_users
      work.permission_manager.read_users  = evaluator.read_users

      # these are both no-ops if an active embargo/lease isn't present
      Hyrax::EmbargoManager.new(resource: work).apply
      Hyrax::LeaseManager.new(resource: work).apply

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

    trait :with_file_and_work do
      transient do
        members do
          # If you set a depositor on the containing work, propogate that into these members
          additional_attributes = {}
          additional_attributes[:depositor] = depositor if depositor
          [valkyrie_create(:hyrax_file_set, additional_attributes), valkyrie_create(:hyrax_work, additional_attributes)]
        end
      end
    end

    trait :with_one_file_set do
      transient do
        members do
          # If you set a depositor on the containing work, propogate that into this member
          additional_attributes = {}
          additional_attributes[:depositor] = depositor if depositor
          [valkyrie_create(:hyrax_file_set, additional_attributes)]
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
        file_set = members&.find(&:file_set?) ||
                   valkyrie_create(:hyrax_file_set)
        file_set.id
      end
    end

    trait :with_renderings do
      rendering_ids do
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
