FactoryBot.define do
  factory :collection do
    # @example let(:collection) { build(:collection, collection_type_settings: [:not_nestable, :discoverable, :sharable, :allow_multiple_membership]) }

    transient do
      user { create(:user) }
      # allow defaulting to default user collection
      collection_type_settings nil
      with_permission_template false
      create_access false
    end
    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      if evaluator.collection_type_settings.present?
        collection.collection_type = create(:collection_type, *evaluator.collection_type_settings)
      elsif collection.collection_type_gid.nil?
        collection.collection_type = create(:user_collection_type)
      end
    end

    after(:create) do |collection, evaluator|
      # create the permission template if it was requested, OR if nested reindexing is included (so we can apply the user's
      # permissions).  Nested indexing requires that the user's permissions be saved on the Fedora object... if simply in
      # local memory, they are lost when the adapter pulls the object from Fedora to reindex.
      if evaluator.with_permission_template || evaluator.create_access || RSpec.current_example.metadata[:with_nested_reindexing]
        attributes = { source_id: collection.id, source_type: 'collection' }
        attributes[:manage_users] = CollectionFactoryHelper.user_managers(evaluator.with_permission_template, evaluator.user,
                                                                          (evaluator.create_access || RSpec.current_example.metadata[:with_nested_reindexing]))
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
        collection.update_access_controls!
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

  factory :user_collection, class: Collection do
    transient do
      user { create(:user) }
    end

    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      collection_type = create(:user_collection_type)
      collection.collection_type_gid = collection_type.gid
    end
  end

  factory :typeless_collection, class: Collection do
    # To create a pre-Hyrax 2.1.0 collection without a collection type gid...
    #   col = build(:typeless_collection, ...)
    #   col.save(validate: false)
    transient do
      user { create(:user) }
      with_permission_template false
      create_access false
      do_save false
    end

    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      collection.save(validate: false) if evaluator.do_save || evaluator.with_permission_template
      if evaluator.with_permission_template
        attributes = { source_id: collection.id, source_type: 'collection' }
        attributes[:manage_users] = [evaluator.user] if evaluator.create_access
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
      end
    end
  end

  class CollectionFactoryHelper
    def self.user_managers(permission_template_attributes, creator_user, include_creator = false)
      managers = []
      managers << creator_user.user_key if include_creator
      return managers unless permission_template_attributes.respond_to?(:merge)
      return managers unless permission_template_attributes.key?(:manage_users)
      managers + permission_template_attributes[:manage_users]
    end
  end
end
