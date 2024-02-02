# frozen_string_literal: true
FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
    file { File.open(Hyrax::Engine.root.join('spec', 'fixtures', 'image.jp2').to_s) }

    trait :audio do
      file { File.open(Hyrax::Engine.root.join('spec', 'fixtures', 'sample_mpeg4.mp4').to_s) }
    end
  end
end
