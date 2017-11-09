FactoryBot.define do
  factory :file_set do
    transient do
      user { FactoryBot.create(:user) }
      content nil
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key if evaluator.user
    end

    before(:create) do |file_set, evaluator|
      if evaluator.content
        storage_adapter = Valkyrie::StorageAdapter.find(:disk)
        persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        node_builder = Hyrax::FileNodeBuilder.new(storage_adapter: storage_adapter,
                                                  persister: persister)

        node = Hyrax::FileNode.for(file: evaluator.content)
        file_node = node_builder.create(file: evaluator.content, node: node)
        file_set.member_ids += [file_node.id]
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
