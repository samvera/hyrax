FactoryGirl.define do
  factory :collection do
    # @example let(:collection) { build(:collection, collection_type_settings: [:not_nestable, :discoverable, :sharable, :allow_multiple_membership]) }

    transient do
      user { FactoryGirl.create(:user) }
      collection_type_settings [:nestable, :discoverable, :sharable, :allow_multiple_membership]
    end
    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      if collection.collection_type_gid.nil?
        collection_type = FactoryGirl.create(:collection_type, *evaluator.collection_type_settings)
        collection.collection_type_gid = collection_type.gid
      end
    end

    factory :public_collection, traits: [:public]

    trait :public do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :private_collection do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    factory :institution_collection do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end

    factory :named_collection do
      title ['collection title']
      description ['collection description']
    end
  end

  factory :typeless_collection, class: Collection do
    # should not have a collection type assigned
    transient do
      user { FactoryGirl.create(:user) }
    end

    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
