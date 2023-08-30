# frozen_string_literal: true

##
# Use this factory for FileMetadata for Files in valkyrie.
FactoryBot.define do
  factory :hyrax_file_metadata, class: 'Hyrax::FileMetadata' do
    transient do
      use { nil }
      visibility_setting { nil }
    end

    after(:build) do |file_metadata, evaluator|
      if evaluator.visibility_setting
        Hyrax::VisibilityWriter
          .new(resource: file_metadata)
          .assign_access_for(visibility: evaluator.visibility_setting)
      end
      file_metadata.pcdm_use = Hyrax::FileMetadata::Use.uri_for(use: evaluator.use) if evaluator.use
    end

    after(:create) do |file_metadata, evaluator|
      if evaluator.visibility_setting
        writer = Hyrax::VisibilityWriter.new(resource: file_metadata)
        writer.assign_access_for(visibility: evaluator.visibility_setting)
        writer.permission_manager.acl.save
      end
    end

    trait :public do
      transient do
        visibility_setting { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end
    end

    trait :image do
      mime_type { 'image/png' }
    end

    trait :with_file do
      transient do
        file { FactoryBot.create(:uploaded_file) }
        file_set { FactoryBot.valkyrie_create(:hyrax_file_set) }
      end

      after(:build) do |file_metadata, evaluator|
        file_metadata.label = evaluator.file.uploader.filename
        file_metadata.mime_type = evaluator.file.uploader.content_type
        file_metadata.original_filename = evaluator.file.uploader.filename
        file_metadata.recorded_size = evaluator.file.uploader.size
        file_metadata.file_set_id = evaluator.file_set.id
      end

      before(:create) do |file_metadata, evaluator|
        saved = Hyrax.storage_adapter.upload(resource: evaluator.file_set,
                                             file: evaluator.file.uploader.file,
                                             original_filename: evaluator.file.uploader.filename)
        file_metadata.file_identifier = saved.id
      end
    end
  end
end
