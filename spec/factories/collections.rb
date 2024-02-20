# frozen_string_literal: true
FactoryBot.define do
  # Tests that create a Fedora Object are very slow.  This factory lets you control which parts of the object ecosystem
  # get built.
  #
  # PREFERRED: Use build whenever possible.  You can control the creation of the permission template, collection type, and
  #            solr document by passing parameters to the build(:collection_lw) method.  That way you can build only the parts
  #            needed for a specific test.
  #
  # AVOID: Do not use create unless absolutely necessary.  It will create everything including the Fedora object.
  #
  # @example Simple build of a collection with no additional parts created.  Lightest weight.
  #          NOTE: A user is automatically created as the owner of the collection.
  #   let(:collection) { build(:collection_lw) }
  #
  # @example Simple build of a collection with no additional parts created.  User is the owner of the collection.  Lightest weight.
  #   let(:collection) { build(:collection_lw, user:) }
  #
  # @example Simple build of a collection with only solr-document.  Owner is given edit-access in solr-document. Light weight.
  #   let(:collection) { build(:collection_lw, with_solr_document: true) }
  #
  # @example Simple build of a collection with only a permission template created.  Owner is set as a manager.  Light weight.
  #   let(:collection) { build(:collection_lw, with_permission_template: true) }
  #
  # @example Build a collection with only a permission template created.  Permissions are set based on
  #          attributes set for `with_permission_template`.  Middle weight.
  #   # permissions passed thru `with_permission_template` can be any of the following in any combination
  #   let(:permissions) { { manage_users: [user.user_key],  # multiple users can be listed
  #                         deposit_users: [user.user_key],
  #                         view_users: [user.user_key],
  #                         manage_groups: [group_name],    # multiple groups can be listed
  #                         deposit_groups: [group_name],
  #                         view_groups: [group_name],  } }
  #   let(:collection) { build(:collection_lw, user: , with_permission_template: permissions) }
  #
  # @example Build a collection with permission template and solr-document created.  Permissions are set based on
  #          attributes set for `with_permission_template`.  Solr-document includes read/edit access defined based
  #          on attributes passed thru `with_permission_template`.  Middle weight.
  #   # permissions passed thru `with_permission_template` can be any of the following in any combination
  #   let(:permissions) { { manage_users: [user.user_key],  # multiple users can be listed
  #                         deposit_users: [user.user_key],
  #                         view_users: [user.user_key],
  #                         manage_groups: [group_name],    # multiple groups can be listed
  #                         deposit_groups: [group_name],
  #                         view_groups: [group_name],  } }
  #   let(:collection) { build(:collection_lw, user: , with_permission_template: permissions, with_solr_document: true) }
  #
  # @example Build a collection generating its collection type with specific settings. Light Weight.
  #          NOTE: Do not use this approach if you need access to the collection type in the test.
  #          DEFAULT: If `collection_type_settings` and `collection_type` are not specified, then the default
  #          User Collection type will be used.
  #   # Any not specified default to ON.  At least one setting should be specified.
  #   let(:settings) { [
  #                      :nestable,                  # OR :not_nestable,
  #                      :discoverable,              # OR :not_discoverable
  #                      :brandable,                 # OR :not_brandable
  #                      :sharable,                  # OR :not_sharable OR :sharable_no_work_permissions
  #                      :allow_multiple_membership, # OR :not_allow_multiple_membership
  #                    ] }
  #   let(:collection) { build(:collection_lw, collection_type_settings: settings) }
  #
  # @example Build a collection using the passed in collection type.  Light Weight.
  #          NOTE: Use this approach if you need access to the collection type in the test.
  #   # Any not specified default to ON.  At least one setting should be specified.
  #   let(:settings) { [
  #                      :nestable,                  # OR :not_nestable,
  #                      :discoverable,              # OR :not_discoverable
  #                      :brandable,                 # OR :not_brandable
  #                      :sharable,                  # OR :not_sharable OR :sharable_no_work_permissions
  #                      :allow_multiple_membership, # OR :not_allow_multiple_membership
  #                    ] }
  #   let(:collection_type) { create(:collection_lw_type, settings) }
  #   let(:collection) { build(:collection_lw, collection_type: collection_type) }

  factory :collection_lw, class: Collection do
    transient do
      user { FactoryBot.create(:user) }

      collection_type { nil }
      collection_type_settings { nil }
      with_permission_template { false }
      with_solr_document { false }
    end
    sequence(:title) { |n| ["Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.collection_type_gid = evaluator.collection_type.to_global_id if evaluator.collection_type&.id.present?
      collection.apply_depositor_metadata(evaluator.user.user_key)

      CollectionLwFactoryHelper.process_collection_type_settings(collection, evaluator)
      CollectionLwFactoryHelper.process_with_permission_template(collection, evaluator)
      CollectionLwFactoryHelper.process_with_solr_document(collection, evaluator)
    end

    before(:create) do |collection, evaluator|
      # force create a permission template if it doesn't exist for the newly created collection
      CollectionLwFactoryHelper.process_with_permission_template(collection, evaluator, true) unless evaluator.with_permission_template
    end

    after(:create) do |collection, _evaluator|
      collection.permission_template.reset_access_controls_for(collection: collection, interpret_visibility: true)
    end

    factory :public_collection_lw, traits: [:public_lw]

    factory :private_collection_lw do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end

    factory :institution_collection_lw do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end

    factory :named_collection_lw do
      title { ['collection title'] }
      description { ['collection description'] }
    end

    trait :public_lw do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    trait :private_lw do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end

    trait :institution_lw do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end

    trait :public_lw do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
  end

  factory :user_collection_lw, class: Collection do
    transient do
      user { FactoryBot.create(:user) }
      collection_type { create(:user_collection_type) }
    end

    sequence(:title) { |n| ["User Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
    end
  end

  factory :typeless_collection_lw, class: Collection do
    # To create a pre-Hyrax 2.1.0 collection without a collection type gid...
    #   col = build(:typeless_collection, ...)
    #   col.save(validate: false)
    transient do
      user { FactoryBot.create(:user) }
      with_permission_template { false }
      do_save { false }
    end

    sequence(:title) { |n| ["Typeless Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      collection.save(validate: false) if evaluator.do_save || evaluator.with_permission_template
      if evaluator.with_permission_template
        attributes = { source_id: collection.id }
        attributes[:manage_users] = [evaluator.user]
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
      end
    end
  end

  class CollectionLwFactoryHelper
    # @returns array of user keys
    def self.permission_from_template(permission_template_attributes, permission_key)
      permissions = []
      return permissions if permission_template_attributes.blank?
      return permissions unless permission_template_attributes.is_a? Hash
      return permissions unless permission_template_attributes.key?(permission_key)
      permission_template_attributes[permission_key]
    end
    private_class_method :permission_from_template

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @parem [String] creator_user is the user who created the new collection
    # @param [Boolean] include_creator, when true, adds the creator_user as a manager
    # @returns array of user keys
    def self.user_managers(permission_template_attributes, creator_user)
      managers = permission_from_template(permission_template_attributes, :manage_users)
      managers << creator_user
      managers
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.group_managers(permission_template_attributes)
      permission_from_template(permission_template_attributes, :manage_groups)
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.user_depositors(permission_template_attributes)
      permission_from_template(permission_template_attributes, :deposit_users)
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.group_depositors(permission_template_attributes)
      permission_from_template(permission_template_attributes, :deposit_groups)
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.user_viewers(permission_template_attributes)
      permission_from_template(permission_template_attributes, :view_users)
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.group_viewers(permission_template_attributes)
      permission_from_template(permission_template_attributes, :view_groups)
    end

    # Process the collection_type_settings transient property such that...
    # * creates the collection type with specified settings if collection_type_settings has settings (ignores collection_type_gid)
    # * uses passed in collection type if collection_type_gid is specified AND collection_type_settings is nil
    # * uses default User Collection type if neither are specified
    # @param [Collection] collection object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    def self.process_collection_type_settings(collection, evaluator)
      if evaluator.collection_type_settings.present?
        collection.collection_type = FactoryBot.create(:collection_type, *evaluator.collection_type_settings)
      elsif collection.collection_type_gid.blank?
        collection.collection_type = FactoryBot.create(:user_collection_type)
      end
    end

    # Process the with_permission_template transient property such that...
    # * a permission template is created for the collection
    # * a permission template access is created for the collection creator
    # * additional permission template accesses are created for each user/group identified in the attributes
    #   of with_permission_template (created by the permission_template factory)
    # @param [Collection] collection object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    # @param [Boolean] if true, force the permission template to be created
    def self.process_with_permission_template(collection, evaluator, force = false)
      return unless force || evaluator.with_permission_template
      collection.id ||= FactoryBot.generate(:object_id)
      attributes = { source_id: collection.id }
      attributes[:manage_users] = user_managers(evaluator.with_permission_template, evaluator.user)
      attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
      FactoryBot.create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
    end

    # Process the with_solr_document transient property such that...
    # * a solr document is created for the collection
    # * permissions identified by with_permission_template, if any, are added to the solr fields
    # @param [Collection] collection object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    def self.process_with_solr_document(collection, evaluator)
      return unless evaluator.with_solr_document
      Hyrax::SolrService.add(solr_document_with_permissions(collection, evaluator), commit: true)
    end

    # Return the collection's solr document with permissions added, such that...
    # * permissions identified by with_permission_template, if any, are added to the solr fields
    # @param [Collection] collection object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    # @returns the collection's solr document with permissions added
    def self.solr_document_with_permissions(collection, evaluator)
      collection.id ||= FactoryBot.generate(:object_id)
      collection.edit_users = user_managers(evaluator.with_permission_template, evaluator.user)
      collection.edit_groups = group_managers(evaluator.with_permission_template)
      collection.read_users = user_viewers(evaluator.with_permission_template) +
                              user_depositors(evaluator.with_permission_template)
      collection.read_groups = group_viewers(evaluator.with_permission_template) +
                               group_depositors(evaluator.with_permission_template)
      collection.to_solr
    end
    private_class_method :solr_document_with_permissions
  end
end
