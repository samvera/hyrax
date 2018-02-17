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
  #   let(:collection) { build(:collection_lw)
  #
  # @example Simple build of a collection with no additional parts created.  User is the owner of the collection.  Lightest weight.
  #   let(:collection) { build(:collection_lw, user:)
  #
  # @example Simple build of a collection with only solr-document.  Owner is given edit-access in solr-document. Light weight.
  #   let(:collection) { build(:collection_lw, with_solr_document: true)
  #
  # @example Simple build of a collection with only a permission template created.  Owner is set as a manager.  Light weight.
  #   let(:collection) { build(:collection_lw, with_permission_template: true)
  #
  # @example Build a collection with only a permission template created.  Permissions are set based on
  #          attributes set for with_permission_template.  Middle weight.
  #   # permissions passed thru with_permission_template can be any of the following in any combination
  #   let(:permissions) { { manage_users: [user.user_key],  # multiple users can be listed
  #                         deposit_users: [user.user_key],
  #                         view_users: [user.user_key],
  #                         manage_groups: [group_name],    # multiple groups can be listed
  #                         deposit_groups: [group_name],
  #                         view_groups: [group_name],  } }
  #   let(:collection) { build(:collection_lw, user: , with_permission_template: permissions)
  #
  # @example Build a collection with permission template and solr-document created.  Permissions are set based on
  #          attributes set for with_permission_template.  Solr-document includes read/edit access defined based
  #          on attributes passed thru with_permission_template.  Middle weight.
  #   # permissions passed thru with_permission_template can be any of the following in any combination
  #   let(:permissions) { { manage_users: [user.user_key],  # multiple users can be listed
  #                         deposit_users: [user.user_key],
  #                         view_users: [user.user_key],
  #                         manage_groups: [group_name],    # multiple groups can be listed
  #                         deposit_groups: [group_name],
  #                         view_groups: [group_name],  } }
  #   let(:collection) { build(:collection_lw, user: , with_permission_template: permissions, with_solr_document: true)
  #
  # @example Build a collection generating its collection type with specific settings. Light Weight.
  #          NOTE: Do not use this method if you need access to the collection type in the test.
  #          DEFAULT: If collection_type_settings and collection_type_gid are not specified, then the default
  #          User Collection type will be used.
  #   # Any not specified default to ON.  At least one setting should be specified.
  #   let(:settings) { [
  #                      :nestable,                  # OR :not_nestable,
  #                      :discoverable,              # OR :not_discoverable
  #                      :sharable,                  # OR :not_sharable OR :sharable_no_work_permissions
  #                      :allow_multiple_membership, # OR :not_allow_multiple_membership
  #                    ] }
  #   let(:collection) { build(:collection_lw, collection_type_settings: settings) }
  #
  # @example Create a collection using the passed in collection type.  Light Weight.
  #          NOTE: Use this method if you need access to the collection type in the test.
  #   # Any not specified default to ON.  At least one setting should be specified.
  #   let(:settings) { [
  #                      :nestable,                  # OR :not_nestable,
  #                      :discoverable,              # OR :not_discoverable
  #                      :sharable,                  # OR :not_sharable OR :sharable_no_work_permissions
  #                      :allow_multiple_membership, # OR :not_allow_multiple_membership
  #                    ] }
  #   let(:collection_type) { create(:collection_lw_type, settings)}
  #   let(:collection) { build(:collection_lw, collection_type_gid: collection_type.gid)}
  #
  # @example Build a collection with nesting fields set in the solr document.  Heavy weight.  Runs nesting indexer.
  #   let(:collection) { build(:collection_lw, with_nesting_attributes: true)
  #
  # @example Create a collection with everything.  Extreme heavy weight.  This is very slow and should be avoided.
  #   let(:collection) { create(:collection_lw)

  factory :collection_lw, class: Collection do
    transient do
      user { create(:user) }

      # build options
      collection_type_settings nil
      with_permission_template false
      with_nesting_attributes nil
      with_solr_document false
    end
    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)

      CollectionLwFactoryHelper.process_collection_type_settings(collection, evaluator)
      CollectionLwFactoryHelper.process_with_permission_template(collection, evaluator)
      CollectionLwFactoryHelper.process_with_solr_document(collection, evaluator)
      CollectionLwFactoryHelper.process_with_nesting_attributes(collection, evaluator)
    end

    after(:create) do |collection, evaluator|
      # TODO: -- elr -- Make create do everything
      # create the permission template if it was requested, OR if nested reindexing is included (so we can apply the user's
      # permissions).  Nested indexing requires that the user's permissions be saved on the Fedora object... if simply in
      # local memory, they are lost when the adapter pulls the object from Fedora to reindex.
      if evaluator.with_permission_template || RSpec.current_example.metadata[:with_nested_reindexing]
        attributes = { source_id: collection.id }
        attributes[:manage_users] = CollectionLwFactoryHelper.user_managers(evaluator.with_permission_template, evaluator.user)
        attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
        collection.reset_access_controls!
      end
    end

    factory :public_collection_lw, traits: [:public]

    factory :private_collection_lw do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    factory :institution_collection_lw do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end

    factory :named_collection_lw do
      title ['collection title']
      description ['collection description']
    end

    trait :public_lw do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    trait :private_lw do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    trait :institution_lw do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end

    trait :public_lw do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end

  factory :user_collection_lw, class: Collection do
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

  factory :typeless_collection_lw, class: Collection do
    # To create a pre-Hyrax 2.1.0 collection without a collection type gid...
    #   col = build(:typeless_collection, ...)
    #   col.save(validate: false)
    transient do
      user { create(:user) }
      with_permission_template false
      do_save false
    end

    sequence(:title) { |n| ["Title #{n}"] }

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
      managers << creator_user.user_key
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
    def self.process_with_permission_template(collection, evaluator)
      return unless evaluator.with_permission_template || RSpec.current_example.metadata[:with_nested_reindexing]
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
      return unless evaluator.with_solr_document || RSpec.current_example.metadata[:with_nested_reindexing]
      collection.id ||= FactoryBot.generate(:object_id)
      collection.edit_users = user_managers(evaluator.with_permission_template, evaluator.user)
      collection.edit_groups = group_managers(evaluator.with_permission_template)
      collection.read_users = user_viewers(evaluator.with_permission_template) +
                              user_depositors(evaluator.with_permission_template)
      collection.read_groups = group_viewers(evaluator.with_permission_template) +
                               group_depositors(evaluator.with_permission_template)
      ActiveFedora::SolrService.add(collection.to_solr, commit: true)
    end

    # Process the with_nesting_attributes transient property such that...
    # * TODO: -- elr -- describe what happens
    # @param [Collection] collection object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    def self.process_with_nesting_attributes(collection, evaluator)
      return unless evaluator.with_nesting_attributes.present? && collection.nestable?
      Hyrax::Adapters::NestingIndexAdapter.add_nesting_attributes(
        solr_doc: evaluator.to_solr,
        ancestors: evaluator.with_nesting_attributes[:ancestors],
        parent_ids: evaluator.with_nesting_attributes[:parent_ids],
        pathnames: evaluator.with_nesting_attributes[:pathnames],
        depth: evaluator.with_nesting_attributes[:depth]
      )
    end
  end
end
