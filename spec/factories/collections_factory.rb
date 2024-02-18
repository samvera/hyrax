# frozen_string_literal: true
FactoryBot.define do
  factory :collection do
    # DEPRECATION: This factory is being replaced by collection_lw defined in collections.rb.  New tests should use the
    # light weight collection factory.  DO NOT ADD tests using this factory.
    #
    # rubocop:disable Layout/LineLength
    # @example let(:collection) { build(:collection, collection_type_settings: [:not_nestable, :discoverable, :sharable, :allow_multiple_membership]) }
    # rubocop:enable Layout/LineLength

    transient do
      user { FactoryBot.create(:user) }
      # allow defaulting to default user collection
      collection_type_settings { nil }
      with_permission_template { false }
      create_access { false }
    end
    sequence(:title) { |n| ["Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      if evaluator.collection_type_settings.present?
        collection.collection_type = create(:collection_type, *evaluator.collection_type_settings)
      elsif collection.collection_type_gid.nil?
        collection.collection_type = create(:user_collection_type)
      end
    end

    after(:create) do |collection, evaluator|
      # create the permission template if it was requested
      if evaluator.with_permission_template || evaluator.create_access
        attributes = { source_id: collection.id }
        attributes[:manage_users] = CollectionFactoryHelper.user_managers(evaluator.with_permission_template, evaluator.user, evaluator.create_access)
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
        collection.permission_template.reset_access_controls_for(collection: collection, interpret_visibility: true)
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
      user { FactoryBot.create(:user) }
      collection_type { create(:user_collection_type) }
    end

    sequence(:title) { |n| ["User Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
    end
  end

  factory :typeless_collection, class: Collection do
    # To create a pre-Hyrax 2.1.0 collection without a collection type gid...
    #   col = build(:typeless_collection, ...)
    #   col.save(validate: false)
    transient do
      user { FactoryBot.create(:user) }
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
