# frozen_string_literal: true

##
# Use this factory for generic Hyrax/HydraWorks Collections in valkyrie.
#
# This factory creates a Valkyrized collection set; by default a Hyrax::PcdmCollection
#
# Why the antics around the class?  Because of the Hyrax needs and potential downstream
# applciation needs.
#
# Downstream applications might implement a different collection class and the downstream
# application might leverage other Hyrax factories that create a `:hyrax_collection`
FactoryBot.define do
  factory :hyrax_collection, class: (Hyrax.config.collection_class < Valkyrie::Resource ? Hyrax.config.collection_class : 'CollectionResource'), aliases: [:collection_resource] do
    sequence(:title) { |n| ["The Tove Jansson Collection #{n}"] }
    collection_type_gid { Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s }

    transient do
      with_permission_template { true }
      collection_type { nil }
      with_index { true }
      user { FactoryBot.create(:user) }
      edit_groups { [] }
      edit_users { [] }
      read_groups { [] }
      read_users { [] }
      members { nil }
      access_grants { [] }
    end

    after(:build) do |collection, evaluator|
      collection.depositor ||= evaluator.user.user_key
      collection.collection_type_gid = evaluator.collection_type.to_global_id.to_s if evaluator.collection_type
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

    factory :pcdm_collection, class: 'Hyrax::PcdmCollection' do
    end
  end
end
