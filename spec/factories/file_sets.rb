FactoryGirl.define do
  factory :file_set do
    transient do
      user { FactoryGirl.create(:user) }
      content nil
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key if evaluator.user
    end

    after(:create) do |file_set, evaluator|
      if evaluator.content
        storage_adapter = Valkyrie::StorageAdapter.find(:disk)
        storage_adapter.upload(file: evaluator.content, resource: file_set)
      end
    end

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    trait :public do
      read_groups ["public"]
    end

    trait :registered do
      read_groups ["registered"]
    end
  end
end
