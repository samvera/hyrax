FactoryGirl.define do
  factory :collection_type, class: Hyrax::CollectionType do
    factory :user_collection_type do
      title ['User Collection']
      description ['A user oriented collection type']
      machine_id ['user_collection']
    end
  end
end
