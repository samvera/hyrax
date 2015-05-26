FactoryGirl.define do
  factory :generic_file, class: CurationConcerns::GenericFile do
    factory :file_with_work do
      transient do
        user { FactoryGirl.create(:user) }
        content nil
      end
      batch { FactoryGirl.create(:generic_work, user: user) }

      after(:build) do |file, evaluator|
        file.title = ['testfile']
        file.apply_depositor_metadata(evaluator.user.user_key)
        if evaluator.content
          file.add_file(evaluator.content, path: 'content', original_name: evaluator.content.original_filename)
        end
      end
    end
  end
end
