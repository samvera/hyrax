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
    end

    after(:create) do |file_set, evaluator|
      if evaluator.visibility_setting
        writer = Hyrax::VisibilityWriter.new(resource: file_set)
        writer.assign_access_for(visibility: evaluator.visibility_setting)
        writer.permission_manager.acl.save
      end
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
  end
end
