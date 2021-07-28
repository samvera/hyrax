# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks Collections in valkyrie.
FactoryBot.define do
  factory :hyrax_collection, class: 'Hyrax::PcdmCollection' do
    title               { ['The Tove Jansson Collection'] }
    collection_type_gid { Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id }

    transient do
      edit_groups { [] }
      edit_users { [] }
      read_groups { [] }
      read_users { [] }
      members { nil }
    end

    after(:build) do |collection, evaluator|
      collection.permission_manager.edit_groups = evaluator.edit_groups
      collection.permission_manager.edit_users = evaluator.edit_users
      collection.permission_manager.read_groups = evaluator.read_groups
      collection.permission_manager.read_users = evaluator.read_users
    end

    after(:create) do |collection, evaluator|
      if evaluator.members.present?
        evaluator.members.map do |member|
          member.member_of_collection_ids += [collection.id]
          Hyrax.persister.save(resource: member)
        end
      end
      collection.permission_manager.edit_groups = evaluator.edit_groups
      collection.permission_manager.edit_users = evaluator.edit_users
      collection.permission_manager.read_groups = evaluator.read_groups
      collection.permission_manager.read_users = evaluator.read_users
      collection.permission_manager.acl.save
    end

    trait :public do
      read_groups { ['public'] }
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
