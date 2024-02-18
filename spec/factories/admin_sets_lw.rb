# frozen_string_literal: true
FactoryBot.define do
  # Tests that create a Fedora Object are very slow.  This factory lets you control which parts of the object ecosystem
  # get built.
  #
  # PREFERRED: Use build whenever possible.  You can control the creation of the permission template and solr document
  #            by passing parameters to the build(:admin_set_lw) method.  That way you can build only the parts needed
  #            for a specific test.
  #
  # AVOID: Do not use create unless absolutely necessary.  It will create everything including the Fedora object.
  #
  # @example Simple build of an admin set with no additional parts created.  Lightest weight.
  #          NOTE: A user is automatically created as the owner of the admin set.
  #   let(:adminset) { build(:adminset_lw) }
  #
  # @example Simple build of an admin set with no additional parts created.  User is the owner of the admin set.  Lightest weight.
  #   let(:adminset) { build(:adminset_lw, user:) }
  #
  # @example Simple build of an admin set with only solr-document.  Owner is given edit-access in solr-document. Light weight.
  #   let(:adminset) { build(:adminset_lw, with_solr_document: true) }
  #
  # @example Simple build of an admin set with only a permission template created.  Owner is set as a manager.  Light weight.
  #   let(:adminset) { build(:adminset_lw, with_permission_template: true) }
  #
  # @example Build an admin set with only a permission template created.  Permissions are set based on
  #          attributes set for `with_permission_template`.  Middle weight.
  #   # permissions passed thru `with_permission_template` can be any of the following in any combination
  #   let(:permissions) { { manage_users: [user.user_key],  # multiple users can be listed
  #                         deposit_users: [user.user_key],
  #                         view_users: [user.user_key],
  #                         manage_groups: [group_name],    # multiple groups can be listed
  #                         deposit_groups: [group_name],
  #                         view_groups: [group_name],  } }
  #   let(:adminset) { build(:adminset_lw, user: , with_permission_template: permissions) }
  #
  # @example Build an admin set with permission template and solr-document created.  Permissions are set based on
  #          attributes set for `with_permission_template`.  Solr-document includes read/edit access defined based
  #          on attributes passed thru `with_permission_template`.  Middle weight.
  #   # permissions passed thru `with_permission_template` can be any of the following in any combination
  #   let(:permissions) { { manage_users: [user.user_key],  # multiple users can be listed
  #                         deposit_users: [user.user_key],
  #                         view_users: [user.user_key],
  #                         manage_groups: [group_name],    # multiple groups can be listed
  #                         deposit_groups: [group_name],
  #                         view_groups: [group_name],  } }
  #   let(:adminset) { build(:adminset_lw, user: , with_permission_template: permissions, with_solr_document: true) }
  #
  # @example Create an admin set with everything.  Extreme heavy weight.  This is very slow and should be avoided.
  #          NOTE: Everything gets created.
  #          NOTE: Build options effect created admin sets as follows...
  #                 * `with_permission_template` can specify user/group permissions.  A permission template is always created.
  #                 * `with_solr_document` is ignored.  A solr document is always created.
  #   let(:adminset) { create(:adminset_lw) }
  #
  # @example Build the default admin set with permission template, solr doc, and default adminset's metadata.
  #   let(:default_adminset) { build(:default_adminset) }

  factory :adminset_lw, class: AdminSet do
    transient do
      user { FactoryBot.create(:user) }

      with_permission_template { false }
      with_solr_document { false }
    end
    sequence(:title) { |n| ["Collection Title #{n}"] }

    after(:build) do |adminset, evaluator|
      adminset.creator = [evaluator.user.user_key]

      AdminSetFactoryHelper.process_with_permission_template(adminset, evaluator)
      AdminSetFactoryHelper.process_with_solr_document(adminset, evaluator)
    end

    before(:create) do |adminset, evaluator|
      # force create a permission template if it doesn't exist for the newly created admin set
      AdminSetFactoryHelper.process_with_permission_template(adminset, evaluator, true) unless evaluator.with_permission_template
    end

    after(:create) do |adminset, _evaluator|
      adminset.permission_template.reset_access_controls_for(collection: adminset)
    end

    factory :default_adminset, class: AdminSet do
      transient do
        with_permission_template do
          {
            deposit_groups: [::Ability.registered_group_name],
            manage_groups: [::Ability.admin_group_name]
          }
        end
        with_solr_document { true }
        with_persisted_default_id { true }
      end
      id { AdminSet::DEFAULT_ID }
      title { AdminSet::DEFAULT_TITLE }

      after(:create) do |admin_set, evaluator|
        Hyrax::DefaultAdministrativeSet.update(default_admin_set_id: admin_set.id) if
          evaluator.with_persisted_default_id
      end
    end
  end

  factory :no_solr_grants_adminset, class: AdminSet do
    # Builds a pre-Hyrax 2.1.0 adminset without edit/view grants on the admin set.
    # Do not use with create because the save will cause the solr grants to be created.
    transient do
      user { FactoryBot.create(:user) }
      with_permission_template { true }
      with_solr_document { true }
    end

    sequence(:title) { |n| ["No Solr Grant Admin Set Title #{n}"] }

    after(:build) do |adminset, evaluator|
      adminset.creator = [evaluator.user.user_key]
      AdminSetFactoryHelper.process_with_permission_template(adminset, evaluator, true)
      AdminSetFactoryHelper.process_with_solr_document(adminset, evaluator, true)
    end
  end

  class AdminSetFactoryHelper
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
    # @parem [String] creator_user is the user who created the new admin set
    # @param [Boolean] include_creator, when true, adds the creator_user as a manager
    # @returns array of user keys
    def self.user_managers(permission_template_attributes, creator_user)
      managers = permission_from_template(permission_template_attributes, :manage_users)
      managers << creator_user
      managers.uniq
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.group_managers(permission_template_attributes)
      permission_from_template(permission_template_attributes, :manage_groups).uniq
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.user_depositors(permission_template_attributes)
      permission_from_template(permission_template_attributes, :deposit_users).uniq
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.group_depositors(permission_template_attributes)
      permission_from_template(permission_template_attributes, :deposit_groups).uniq
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.user_viewers(permission_template_attributes)
      permission_from_template(permission_template_attributes, :view_users).uniq
    end

    # @param [Hash] permission_template_attributes where names identify the role and value are the user keys for that role
    # @returns array of user keys
    def self.group_viewers(permission_template_attributes)
      permission_from_template(permission_template_attributes, :view_groups).uniq
    end

    # Process the with_permission_template transient property such that...
    # * a permission template is created for the admin set
    # * a permission template access is created for the admin set creator
    # * additional permission template accesses are created for each user/group identified in the attributes
    #   of with_permission_template (created by the permission_template factory)
    # @param [AdminSet] admin set object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    # @param [Boolean] if true, force the permission template to be created
    def self.process_with_permission_template(adminset, evaluator, force = false)
      return unless force || evaluator.with_permission_template
      adminset.id ||= FactoryBot.generate(:object_id)
      attributes = { source_id: adminset.id }
      attributes[:manage_users] = user_managers(evaluator.with_permission_template, evaluator.user)
      attributes = evaluator.with_permission_template.merge(attributes) if evaluator.with_permission_template.respond_to?(:merge)
      FactoryBot.create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: adminset.id)
    end

    # Process the with_solr_document transient property such that...
    # * a solr document is created for the admin set
    # * permissions identified by with_permission_template, if any, are added to the solr fields
    # @param [AdminSet] adminset object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    def self.process_with_solr_document(adminset, evaluator, creator_only = false)
      return unless creator_only || evaluator.with_solr_document
      Hyrax::SolrService.add(solr_document_with_permissions(adminset, evaluator, creator_only), commit: true)
    end

    # Return the admin set's solr document with permissions added, such that...
    # * permissions identified by with_permission_template, if any, are added to the solr fields
    # @param [AdminSet] adminset object being built/created by the factory
    # @param [Class] evaluator holding the transient properties for the current build/creation process
    # @returns the admin set's solr document with permissions added
    def self.solr_document_with_permissions(adminset, evaluator, creator_only)
      adminset.id ||= FactoryBot.generate(:object_id)
      if creator_only
        adminset.edit_users = [evaluator.user]
      else
        adminset.edit_users = user_managers(evaluator.with_permission_template, evaluator.user)
        adminset.edit_groups = group_managers(evaluator.with_permission_template)
        adminset.read_users = user_viewers(evaluator.with_permission_template) +
                              user_depositors(evaluator.with_permission_template)
        adminset.read_groups = group_viewers(evaluator.with_permission_template) +
                               group_depositors(evaluator.with_permission_template) -
                               [::Ability.registered_group_name, ::Ability.public_group_name]
      end
      adminset.to_solr
    end
    private_class_method :solr_document_with_permissions
  end
end
