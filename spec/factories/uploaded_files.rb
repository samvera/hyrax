# frozen_string_literal: true
FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
    file { File.open(Hyrax::Engine.root + 'spec/fixtures/image.jp2') }

    trait :audio do
      file { File.open(Hyrax::Engine.root + 'spec/fixtures/sample_mpeg4.mp4') }
    end
  end
end
