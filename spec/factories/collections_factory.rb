FactoryBot.define do
  factory :collection do
    # DEPRECATION: This factory is being replaced by collection_lw defined in collections.rb.  New tests should use the
    # light weight collection factory.  DO NOT ADD tests using this factory.
    #
    # rubocop:disable Metrics/LineLength
    # @example let(:collection) { build(:collection, collection_type_settings: [:not_nestable, :discoverable, :sharable, :allow_multiple_membership], with_nesting_attributes: {ancestors: [], parent_ids: [], pathnames: [], depth: 1}) }
    # rubocop:enable Metrics/LineLength

    # Regarding testing nested collections:
    # To get the nested collection solr fields in the solr document for query purposes there are two options:
    # => 1) use create(:collection) and add "with_nested_reindexing: true" to the spec will force the collection to be
    #       created and run through the entire indexing.
    #    => when you need a permission template AND nesting fields in the solr_document
    #    => certain ability tests (:discover, for example) require the permission template be created
    # => 2) use build(:collection) and add with_nesting_attributes: {ancestors: [], parent_ids: [], pathnames: [], depth: 1}
    #       to the build the collection and create a solr document using the given nesting attributes
    #    => this can be used to speed up the specs when a made-up solr document is adequate and no permission template is required

    transient do
      user { create(:user) }
      # allow defaulting to default user collection
      collection_type_settings { nil }
      with_permission_template { false }
      create_access { false }
      with_nesting_attributes { nil }
    end
    sequence(:title) { |n| ["Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      if evaluator.collection_type_settings.present?
        collection.collection_type = create(:collection_type, *evaluator.collection_type_settings)
      elsif collection.collection_type_gid.nil?
        collection.collection_type = create(:user_collection_type)
      end

      # if requested, create a solr document and add the nesting fields into it
      # when a nestable collection is built. This reduces the need to use
      # create and :with_nested_indexing for nested collection testing
      if evaluator.with_nesting_attributes.present? && collection.nestable?
        Hyrax::Adapters::NestingIndexAdapter.add_nesting_attributes(
          solr_doc: evaluator.to_solr,
          ancestors: evaluator.with_nesting_attributes[:ancestors],
          parent_ids: evaluator.with_nesting_attributes[:parent_ids],
          pathnames: evaluator.with_nesting_attributes[:pathnames],
          depth: evaluator.with_nesting_attributes[:depth]
        )
      end
    end

    after(:create) do |collection, evaluator|
      # create the permission template if it was requested, OR if nested reindexing is included (so we can apply the user's
      # permissions).  Nested indexing requires that the user's permissions be saved on the Fedora object... if simply in
      # local memory, they are lost when the adapter pulls the object from Fedora to reindex.
      if evaluator.with_permission_template || evaluator.create_access || RSpec.current_example.metadata[:with_nested_reindexing]
        attributes = { source_id: collection.id }
        attributes[:manage_users] = CollectionFactoryHelper.user_managers(evaluator.with_permission_template, evaluator.user,
                                                                          (evaluator.create_access || RSpec.current_example.metadata[:with_nested_reindexing]))
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
        collection.reset_access_controls!
      end
    end

    factory :public_collection, traits: [:public]

    trait :public do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    factory :private_collection do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end

    factory :institution_collection do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end

    factory :named_collection do
      title { ['collection title'] }
      description { ['collection description'] }
    end
  end

  factory :user_collection, class: Collection do
    transient do
      user { create(:user) }
    end

    sequence(:title) { |n| ["User Collection Title #{n}"] }

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
      with_permission_template { false }
      create_access { false }
      do_save { false }
    end

    sequence(:title) { |n| ["Typeless Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      collection.save(validate: false) if evaluator.do_save || evaluator.with_permission_template
      if evaluator.with_permission_template
        attributes = { source_id: collection.id }
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
