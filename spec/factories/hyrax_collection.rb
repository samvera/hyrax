# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks Collections in valkyrie.
FactoryBot.define do
  factory :hyrax_collection, class: 'Hyrax::Collection' do
    title               { ['The Tove Jansson Collection'] }
    collection_type_gid { Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id }

    transient do
      members { nil }
    end

    after(:build) do |collection, evaluator|
      collection.member_ids = evaluator.members.map(&:id) if evaluator.members
    end

    trait :with_member_works do
      transient do
        members { [valkyrie_create(:hyrax_work), valkyrie_create(:hyrax_work)] }
      end
    end

    trait :with_member_collections do
      transient do
        members { [valkyrie_create(:hyrax_collection), valkyrie_create(:hyrax_collection)] }
      end
    end
  end
end
