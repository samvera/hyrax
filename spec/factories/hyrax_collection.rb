# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks Collections in valkyrie.
FactoryBot.define do
  factory :hyrax_collection, class: 'Hyrax::PcdmCollection', aliases: [:pcdm_collection] do
    sequence(:title) { |n| ["The Tove Jansson Collection #{n}"] }
    collection_type_gid { Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s }

    transient do
      with_permission_template { true }
      with_index { true }
      user { create(:user) }
      edit_groups { [] }
      edit_users { [] }
      read_groups { [] }
      read_users { [] }
      members { nil }
      access_grants { [] }
    end

    after(:create) do |collection, evaluator|
      if evaluator.members.present?
        evaluator.members.map do |member|
          member.member_of_collection_ids += [collection.id]
          member = Hyrax.persister.save(resource: member)
          Hyrax.index_adapter.save(resource: member) if evaluator.with_index
        end
      end
      if evaluator.with_permission_template
        Hyrax::Collections::PermissionsCreateService.create_default(collection: collection,
                                                                    creating_user: evaluator.user,
                                                                    grants: evaluator.access_grants)
        collection.permission_manager.edit_groups = collection.permission_manager.edit_groups.to_a +
                                                    evaluator.edit_groups
        collection.permission_manager.edit_users = collection.permission_manager.edit_users.to_a +
                                                   evaluator.edit_users
        collection.permission_manager.read_groups = collection.permission_manager.read_groups.to_a +
                                                    evaluator.read_groups
        collection.permission_manager.read_users = collection.permission_manager.read_users.to_a +
                                                   evaluator.read_users
        collection.permission_manager.acl.save
      end
      Hyrax.index_adapter.save(resource: collection) if evaluator.with_index
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

    trait :as_collection_member do
      member_of_collection_ids { [valkyrie_create(:hyrax_collection).id] }
    end

    trait :as_member_of_multiple_collections do
      member_of_collection_ids do
        [valkyrie_create(:hyrax_collection).id,
         valkyrie_create(:hyrax_collection).id,
         valkyrie_create(:hyrax_collection).id]
      end
    end

    factory :collection_resource, class: 'CollectionResource' do
    end
  end
end
