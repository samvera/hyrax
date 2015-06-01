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
        if evaluator.content
          file.add_file(evaluator.content, path: 'content', original_name: evaluator.content.original_filename)
        end
      end
    end
    before(:create) do |file, evaluator|
      file.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
