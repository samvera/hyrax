# frozen_string_literal: true
module Hyrax
  ##
  # Provides Hyrax's engine level user/group authorizations.
  #
  # Authorization (allow or deny) of the following actions is managed by the
  # rules defined here:
  #
  #   - read:
  #   - show:
  #   - edit:
  #   - update:
  #   - create:
  #   - discover:
  #   - manage:
  #   - download:
  #   - destroy:
  #   - collect:
  #   - toggle_trophy:
  #   - transfer:
  #   - accept:
  #   - reject:
  #   - manage_any:
  #   - create_any:
  #   - view_admin_show_any:
  #   - review:
  #   - create_collection_type:
  #
  # @note This is intended as a mixin layered over
  #   +Blacklight::AccessControls::Ability+ and +Hydra::AccessControls+. Its
  #   implementation may depend in part on behavioral details of either of those
  #   two mixins. As of Hyrax 3.0.0 there's an ongoing effort to clarify and
  #   document the specific dependencies.
  #
  # @todo catalog and document the actions we authorize here. everything we
  #   allow or disable from this module should be clear to application side
  #   adopters.
  #
  # @example creating an application Ability
  #   # app/models/ability.rb
  #   class Ability
  #     include Hydra::Ability
  #     include Hyrax::Ability
  #   end
  #
  # @see https://www.rubydoc.info/github/CanCanCommunity/cancancan
  # @see https://www.rubydoc.info/gems/blacklight-access_controls/
  module Ability
    extend ActiveSupport::Concern

    included do
      include Hyrax::Ability::AdminSetAbility
      include Hyrax::Ability::CollectionAbility
      include Hyrax::Ability::CollectionTypeAbility
      include Hyrax::Ability::PermissionTemplateAbility
      include Hyrax::Ability::ResourceAbility
      include Hyrax::Ability::SolrDocumentAbility

      class_attribute :admin_group_name, :registered_group_name, :public_group_name
      self.admin_group_name = Hyrax.config.admin_user_group_name
      self.registered_group_name = Hyrax.config.registered_user_group_name
      self.public_group_name = Hyrax.config.public_user_group_name
      self.ability_logic += [:admin_permissions,
                             :edit_resources,
                             :curation_concerns_permissions,
                             :operation_abilities,
                             :add_to_collection,
                             :user_abilities,
                             :featured_work_abilities,
                             :editor_abilities,
                             :stats_abilities,
                             :citation_abilities,
                             :proxy_deposit_abilities,
                             :uploaded_file_abilities,
                             :feature_abilities,
                             :admin_set_abilities,
                             :collection_abilities,
                             :collection_type_abilities,
                             :permission_template_abilities,
                             :resource_abilities,
                             :solr_document_abilities,
                             :trophy_abilities]
    end

    # Samvera doesn't use download user/groups, so make it an alias to read
    # Grant all groups with read or edit access permission to download
    def download_groups(id)
      doc = permissions_doc(id)
      return [] if doc.nil?
      groups = Array(doc[self.class.read_group_field]) + Array(doc[self.class.edit_group_field])
      Hyrax.logger.debug("[CANCAN] download_groups: #{groups.inspect}")
      groups
    end

    # Grant all users with read or edit access permission to download
    def download_users(id)
      doc = permissions_doc(id)
      return [] if doc.nil?
      users = Array(doc[self.class.read_user_field]) + Array(doc[self.class.edit_user_field])
      Hyrax.logger.debug("[CANCAN] download_users: #{users.inspect}")
      users
    end

    # Returns true if can create at least one type of work and they can deposit
    # into at least one AdminSet
    def can_create_any_work?
      curation_concerns_models.any? do |curation_concern_type|
        can?(:create, curation_concern_type)
      end && admin_set_with_deposit?
    end

    # Override this method in your ability model if you use a different group
    # or other logic to designate an administrator.
    def admin?
      user_groups.include? admin_group_name
    end

    private

    # @!group Ability Logic Library

    ##
    # @api public
    #
    # Overrides hydra-head, (and restores the method from blacklight-access-controls)
    def download_permissions
      can :download, [::String, ::Valkyrie::ID] do |id|
        test_download(id.to_s)
      end

      can :download, ::SolrDocument do |obj|
        cache.put(obj.id, obj)
        test_download(obj.id)
      end
    end

    ##
    # @api public
    #
    # Allows
    def edit_resources
      can [:edit, :update, :destroy], Hyrax::Resource do |resource|
        test_edit(resource.id)
      end
    end

    ##
    # @api public
    #
    # Add this to your {.ability_logic} if you want all logged in users to be able
    # to submit content.
    #
    # @note this is normally injected into an application +::Ability+ by the
    #   hyrax install generator.
    #
    # @example
    #   self.ability_logic += [:everyone_can_create_curation_concerns]
    def everyone_can_create_curation_concerns
      return unless registered_user?
      can :create, curation_concerns_models
    end

    ##
    # @api public
    #
    # Allow registered users to create {UploadedFile} and {BatchUploadItem}
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:uploaded_file_abilities]
    def uploaded_file_abilities
      return unless registered_user?
      can :create, [UploadedFile, BatchUploadItem]
      can :destroy, UploadedFile, user: current_user
      # BatchUploadItem permissions depend on the kind of objects being made by the batch,
      # but it must be authorized directly in the controller, not here.
      # Note: cannot call `authorized_models` without going recursive.
    end

    ##
    # @api public
    #
    # Permissions for work transfers and proxy deposit models.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:proxy_deposit_abilities]
    def proxy_deposit_abilities
      if Flipflop.transfer_works?
        can :transfer, [::String, Valkyrie::ID] do |id|
          user_is_depositor?(id.to_s)
        end
      end

      can :create, ProxyDepositRequest if (Flipflop.proxy_deposit? || Flipflop.transfer_works?) && registered_user?

      can :accept, ProxyDepositRequest, receiving_user_id: current_user.id, status: 'pending'
      can :reject, ProxyDepositRequest, receiving_user_id: current_user.id, status: 'pending'
      # a user who sent a proxy deposit request can cancel it if it's pending.
      can :destroy, ProxyDepositRequest, sending_user_id: current_user.id, status: 'pending'
    end

    ##
    # @api public
    #
    # Permissions for users to edit themselves and view other users
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:user_abilities]
    def user_abilities
      can [:edit, :update, :toggle_trophy], ::User, id: current_user.id
      can :show, ::User
    end

    ##
    # @api public
    #
    # Allow admins to manage {FeaturedWork} data.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:featured_work_abilities]
    def featured_work_abilities
      can [:create, :destroy, :update], FeaturedWork if admin?
    end

    ##
    # @api public
    #
    # Allow everyone to read {ContentBlock} data.
    #
    # Allow admins to read the admin dashboard, update {ContentBlock}, and edit
    # {SolrDocument}(!?)
    #
    # @todo why does this allow so many different things? what is going on with
    #   `can :edit, ::SolrDocument`.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:editor_abilities]
    def editor_abilities
      can :read, ContentBlock
      return unless admin?

      can :read, :admin_dashboard
      can :update, ContentBlock
      can :edit, ::SolrDocument
    end

    ##
    # @api public
    #
    # Allow admins to read {Hyrax::Statistics}; allow read users to do the
    # +:stats+ action.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:stats_abilities]
    def stats_abilities
      can :read, Hyrax::Statistics if admin?
      alias_action :stats, to: :read
    end

    ##
    # @api public
    #
    # Allow read users to do the +:citation+ action
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:citation_abilities]
    def citation_abilities
      alias_action :citation, to: :read
    end

    ##
    # @api public
    #
    # Allow admin users to manage {Hyrax::Feature} data.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:feature_abilities]
    def feature_abilities
      can :manage, Hyrax::Feature if admin?
    end

    ##
    # @api public
    #
    # Allow users to read their own {Hyrax::Operation} data.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:operation_abilities]
    def operation_abilities
      can :read, Hyrax::Operation, user_id: current_user.id
    end

    ##
    # @api public
    #
    # Allow depositors to create and destroy {Trophy} data.
    #
    # @note We check based on the depositor, because the depositor may not have
    #   edit access to the work if it went through a mediated deposit workflow
    #   that removes edit access for the depositor.
    #
    # @note included in {.ability_logic} by default.
    #
    # @todo the note isn't very convincing. why do depositors without edit
    #   access need trophy management abilities?
    #
    # @example
    #   self.ability_logic += [:trophy_abilities]
    def trophy_abilities
      can [:create, :destroy], Trophy do |t|
        doc = Hyrax::SolrService.search_by_id(t.work_id, fl: 'depositor_ssim')
        current_user.user_key == doc.fetch('depositor_ssim').first
      end
    end

    ##
    # @api public
    #
    # Allow editor to view versions and the file manager; block non-admins from
    # indexing embargo and lease.
    #
    # @note included in {.ability_logic} by default.
    # @todo make this do one thing. extract embargo/lease rules elsewhere.
    #
    # @example
    #   self.ability_logic += [:curation_concerns_permissions]
    def curation_concerns_permissions
      # user can version if they can edit
      alias_action :versions, to: :update
      alias_action :file_manager, to: :update

      return if admin?
      cannot :index, Hydra::AccessControls::Embargo
      cannot :index, Hydra::AccessControls::Lease
    end

    ##
    # @api public
    #
    # Give admins sweeping permissions.
    #
    # @note included in {.ability_logic} by default.
    #
    # @example
    #   self.ability_logic += [:admin_permissions]
    def admin_permissions
      return unless admin?
      # TODO: deprecate this. We no longer have a dashboard just for admins
      can :read, :admin_dashboard
      alias_action :edit, to: :update
      alias_action :show, to: :read
      alias_action :discover, to: :read
      can :update, :appearance
      can :manage, [String, Valkyrie::ID] # The identifier of a work or FileSet
      can :manage, curation_concerns_models
      can :manage, Sipity::WorkflowResponsibility
      can :manage, :collection_types
      can :manage, ::FileSet
    end

    ##
    # @api public
    #
    # Allow registered users to +:collect+ everything, and to +:files+ thing
    # they can read.
    #
    # @note included in {.ability_logic} by default.
    #
    # @todo what in the world does it mean to +:files+? what does "members will
    #   be filtered separately" mean?
    #
    # @example
    #   self.ability_logic += [:add_to_collection]
    def add_to_collection
      return unless registered_user?
      alias_action :files, to: :read # members will be filtered separately
      can :collect, :all
    end

    # @!endgroup

    # @return [Boolean] true if the user has at least one admin set they can deposit into.
    def admin_set_with_deposit?
      ids = PermissionTemplateAccess.for_user(ability: self,
                                              access: ['deposit', 'manage'])
                                    .joins(:permission_template)
                                    .select(:source_id)
                                    .distinct
                                    .pluck(:source_id)
      return false if ids.empty?
      Hyrax::SolrQueryService.new.with_ids(ids: ids).query_result(rows: 1000)['response']['docs'].any? do |doc|
        (Hyrax::ModelRegistry.admin_set_rdf_representations & doc['has_model_ssim']).present?
      end
    end

    def registered_user?
      return false if current_user.guest?
      user_groups.include? registered_group_name
    end

    # Returns true if the current user is the depositor of the specified work
    # @param document_id [String, Valkyrie::ID] the id of the document.
    def user_is_depositor?(document_id)
      doc = Hyrax::SolrService.search_by_id(document_id.to_s, fl: 'depositor_ssim')
      current_user.user_key == doc['depositor_ssim']&.first
    end

    def curation_concerns_models
      Hyrax::ModelRegistry.collection_classes + Hyrax::ModelRegistry.file_set_classes + Hyrax::ModelRegistry.work_classes
    end

    def can_review_submissions?
      # Short-circuit logic for admins, who should have the ability
      # to review submissions whether or not they are explicitly
      # granted the approving role in any workflows
      return true if admin?

      # Are there any workflows where this user has the "approving" responsibility
      approving_role = Sipity::Role.find_by(name: Hyrax::RoleRegistry::APPROVING)
      return false unless approving_role
      Hyrax::Workflow::PermissionQuery.scope_processing_agents_for(user: current_user).any? do |agent|
        agent.workflow_responsibilities.joins(:workflow_role)
             .where('sipity_workflow_roles.role_id' => approving_role.id).any?
      end
    end

    def extract_subjects(subject)
      case subject
      when Hyrax::WorkShowPresenter, FileSetPresenter, Hyrax::CollectionPresenter
        extract_subjects(subject.solr_document)
      when Draper::Decorator
        extract_subjects(subject.model)
      else
        super
      end
    end
  end
end
