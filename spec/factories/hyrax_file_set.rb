# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks FileSets in valkyrie.
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
    end

    after(:build) do |file_set, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: file_set)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end
      file_set.file_ids = evaluator.files.map(&:id) if evaluator.files
      file_set.original_file_id = evaluator.original_file.id if evaluator.original_file
      file_set.extracted_text_id = evaluator.extracted_text.id if evaluator.extracted_text
      file_set.thumbnail_id = evaluator.thumbnail.id if evaluator.thumbnail

      file_set.permission_manager.edit_groups = evaluator.edit_groups
      file_set.permission_manager.edit_users  = evaluator.edit_users
      file_set.permission_manager.read_users  = evaluator.read_users
      file_set.permission_manager.read_users  = evaluator.read_groups
    end

    after(:create) do |file_set, evaluator|
      if evaluator.visibility_setting
        writer = Hyrax::VisibilityWriter.new(resource: file_set)
        writer.assign_access_for(visibility: evaluator.visibility_setting)
        writer.permission_manager.acl.save
      end

      file_set.permission_manager.edit_groups = evaluator.edit_groups
      file_set.permission_manager.edit_users  = evaluator.edit_users
      file_set.permission_manager.read_users  = evaluator.read_users
      file_set.permission_manager.read_users  = evaluator.read_groups

      file_set.permission_manager.acl.save
    end

    trait :public do
      transient do
        visibility_setting { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
    end

    trait :with_files do
      transient do
        files { [valkyrie_create(:hyrax_file_metadata), valkyrie_create(:hyrax_file_metadata)] }
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
