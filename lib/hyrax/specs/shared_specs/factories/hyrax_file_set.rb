# frozen_string_literal: true

FactoryBot.define do
  factory :hyrax_file_set, class: 'Hyrax::FileSet' do
    transient do
      files              { nil }
      original_file      { nil }
      extracted_text     { nil }
      thumbnail          { nil }
      visibility_setting { nil }
      edit_users         { [] }
      edit_groups        { [] }
      read_users         { [] }
      read_groups        { [] }
      with_index         { true }
    end

    after(:build) do |file_set, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: file_set)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end
      file_set.file_ids = evaluator.files.map(&:id) if evaluator.files

      file_set.permission_manager.edit_groups = file_set.permission_manager.edit_groups.to_a + evaluator.edit_groups
      file_set.permission_manager.edit_users  = file_set.permission_manager.edit_users.to_a + evaluator.edit_users
      file_set.permission_manager.read_users  = file_set.permission_manager.read_users.to_a + evaluator.read_users
      file_set.permission_manager.read_groups = file_set.permission_manager.read_groups.to_a + evaluator.read_groups
    end

    after(:create) do |file_set, evaluator|
      if evaluator.visibility_setting
        writer = Hyrax::VisibilityWriter.new(resource: file_set)
        writer.assign_access_for(visibility: evaluator.visibility_setting)
        writer.permission_manager.acl.save
      end

      file_set.permission_manager.edit_groups = file_set.permission_manager.edit_groups.to_a + evaluator.edit_groups
      file_set.permission_manager.edit_users  = file_set.permission_manager.edit_users.to_a + evaluator.edit_users
      file_set.permission_manager.read_users  = file_set.permission_manager.read_users.to_a + evaluator.read_users
      file_set.permission_manager.read_groups = file_set.permission_manager.read_groups.to_a + evaluator.read_groups

      file_set.permission_manager.acl.save

      Hyrax.index_adapter.save(resource: file_set) if evaluator.with_index
    end

    trait :under_embargo do
      association :embargo, factory: :hyrax_embargo

      after(:create) do |fs, _e|
        Hyrax::EmbargoManager.new(resource: fs).apply
        fs.permission_manager.acl.save
      end
    end

    trait :with_expired_enforced_embargo do
      after(:build) do |fs, _evaluator|
        fs.embargo = FactoryBot.valkyrie_create(:hyrax_embargo, :expired)
      end

      after(:create) do |fs, _evaluator|
        allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(10.days.ago)
        Hyrax::EmbargoManager.new(resource: fs).apply
        fs.permission_manager.acl.save
        allow(Hyrax::TimeService).to receive(:time_in_utc).and_call_original
      end
    end

    trait :under_lease do
      association :lease, factory: :hyrax_lease

      after(:create) do |fs, _e|
        Hyrax::LeaseManager.new(resource: fs).apply
        fs.permission_manager.acl.save
      end
    end

    trait :with_expired_enforced_lease do
      after(:build) do |fs, _evaluator|
        fs.lease = FactoryBot.valkyrie_create(:hyrax_lease, :expired)
      end

      after(:create) do |fs, _evaluator|
        allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(10.days.ago)
        Hyrax::LeaseManager.new(resource: fs).apply
        fs.permission_manager.acl.save
        allow(Hyrax::TimeService).to receive(:time_in_utc).and_call_original
      end
    end

    trait :public do
      transient do
        visibility_setting { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
    end

    trait :authenticated do
      transient do
        visibility_setting { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      end
    end

    trait :with_files do
      transient do
        ios { [File.open(Hyrax::Engine.root + 'spec/fixtures/image.png'), File.open(Hyrax::Engine.root + 'spec/fixtures/Example.ogg')] }

        after(:create) do |file_set, evaluator|
          evaluator.ios.each do |file|
            filename = File.basename(file.path).to_s
            Hyrax::ValkyrieUpload.file(filename: filename, file_set: file_set, io: file)
          end
        end
      end
    end

    trait :in_work do
      transient do
        work { build(:hyrax_work) }
      end

      after(:create) do |file_set, evaluator|
        evaluator.work.member_ids += [file_set.id]
        Hyrax.persister.save(resource: evaluator.work)
      end
    end
  end
end
