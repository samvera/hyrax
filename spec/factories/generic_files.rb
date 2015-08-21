FactoryGirl.define do
  # The ::GenericFile model is defined in spec/internal/app/models by the
  # curation_concerns:install generator.
  factory :generic_file, class: GenericFile do
    transient do
      user { FactoryGirl.create(:user) }
      content nil
    end

    after(:create) do |file, evaluator|
      if evaluator.content
        Hydra::Works::UploadFileToGenericFile.call(file, evaluator.content)
      end
    end

    factory :file_with_work do
      after(:build) do |file, _evaluator|
        file.title = ['testfile']
      end
      after(:create) do |file, evaluator|
        if evaluator.content
          Hydra::Works::UploadFileToGenericFile.call(file, evaluator.content)
        end
        FactoryGirl.create(:generic_work, user: evaluator.user).generic_files << file
      end
    end
    after(:build) do |file, evaluator|
      file.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
