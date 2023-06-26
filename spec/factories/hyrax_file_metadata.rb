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
      file_metadata.type = Hyrax::FileMetadata::Use.uri_for(use: evaluator.use) if evaluator.use
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
  end
end
