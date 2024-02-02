# frozen_string_literal: true
FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
<<<<<<< HEAD
    file { File.open(Hyrax::Engine.root + 'spec/fixtures/image.jp2') }

    trait :audio do
      file { File.open(Hyrax::Engine.root + 'spec/fixtures/sample_mpeg4.mp4') }
=======
    file { File.open(Hyrax::Engine.root.join('spec', 'fixtures', 'image.jp2').to_s) }

    trait :audio do
      file { File.open(Hyrax::Engine.root.join('spec', 'fixtures', 'sample_mpeg4.mp4').to_s) }
>>>>>>> main
    end
  end
end
