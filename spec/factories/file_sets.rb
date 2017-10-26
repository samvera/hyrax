fFactoryGirl.define do
  factory :file_set do
    transient do
      user { FactoryGirl.create(:user) }
      content nil
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key if evaluator.user
    end

    before(:create) do |file_set, evaluator|
      if evaluator.content
        storage_adapter = Valkyrie::StorageAdapter.find(:disk)
        persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        appender = Hyrax::FileAppender.new(storage_adapter: storage_adapter,
                                           persister: persister,
                                           files: [evaluator.content])
        appender.append_to(file_set)
      end
    end

    to_create do |instance|
      persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      persister.save(resource: instance)
    end

    trait :public do
      read_groups ["public"]
    end

    trait :registered do
      read_groups ["registered"]
    end
  end
end
