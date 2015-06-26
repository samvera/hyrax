FactoryGirl.define do
  factory :generic_file, class: CurationConcerns::GenericFile do
    transient do
      user { FactoryGirl.create(:user) }
      content nil
    end

    factory :file_with_work do

      batch { FactoryGirl.create(:generic_work, user: user) }

      after(:build) do |file, evaluator|
        file.title = ['testfile']
      end
      after(:create) do |file, evaluator|
        if evaluator.content
          # Hydra::Works::AddFileToGenericFile.call(file, evaluator.content, :original_file)
          Hydra::Works::UploadFileToGenericFile.call(file, evaluator.content)
        end
      end
    end
    before(:create) do |file, evaluator|
      file.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
