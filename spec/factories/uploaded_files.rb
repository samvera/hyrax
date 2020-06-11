# frozen_string_literal: true
FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
  end
end
