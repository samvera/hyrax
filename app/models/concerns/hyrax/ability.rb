module Hyrax
  module Ability
    extend ActiveSupport::Concern

    included do
      include Hyrax::Ability::AdminSetAbility
      include Hyrax::Ability::CollectionAbility
      include Hyrax::Ability::CollectionTypeAbility
      include Hyrax::Ability::PermissionTemplateAbility
      include Hyrax::Ability::SolrDocumentAbility

      class_attribute :admin_group_name, :registered_group_name, :public_group_name
      self.admin_group_name = 'admin'
      self.registered_group_name = 'registered'
      self.public_group_name = 'public' # TODO: find hard coded values and replace with this
      self.ability_logic += [:admin_permissions,
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
                             :solr_document_abilities,
                             :trophy_abilities]
    end

    # Samvera doesn't use download user/groups, so make it an alias to read
    # Grant all groups with read or edit access permission to download
    def download_groups(id)
      doc = permissions_doc(id)
      return [] if doc.nil?
      groups = Array(doc[self.class.read_group_field]) + Array(doc[self.class.edit_group_field])
      Rails.logger.debug("[CANCAN] download_groups: #{groups.inspect}")
      groups
    end

    # Grant all users with read or edit access permission to download
    def download_users(id)
      doc = permissions_doc(id)
      return [] if doc.nil?
      users = Array(doc[self.class.read_user_field]) + Array(doc[self.class.edit_user_field])
      Rails.logger.debug("[CANCAN] download_users: #{users.inspect}")
      users
    end

    # Returns true if can create at least one type of work and they can deposit
    # into at least one AdminSet
    def can_create_any_work?
      Hyrax.config.curation_concerns.any? do |curation_concern_type|
        can?(:create, curation_concern_type)
      end && admin_set_with_deposit?
    end

    # Override this method in your ability model if you use a different group
    # or other logic to designate an administrator.
    def admin?
      user_groups.include? admin_group_name
    end

    private

    # @return [Boolean] true if the user has at least one admin set they can deposit into.
    def admin_set_with_deposit?
      ids = PermissionTemplateAccess.for_user(ability: self,
                                              access: ['deposit', 'manage'])
                                    .joins(:permission_template)
                                    .select(:source_id)
                                    .distinct
                                    .pluck(:source_id)
      query = "_query_:\"{!raw f=has_model_ssim}AdminSet\" AND {!terms f=id}#{ids.join(',')}"
      Hyrax::SolrService.count(query).positive?
    end

    # This overrides hydra-head, (and restores the method from blacklight-access-controls)
    def download_permissions
      can :download, String do |id|
        test_download(id)
      end

      can :download, SolrDocument do |obj|
        cache.put(obj.id, obj)
        test_download(obj.id)
      end
    end

    # Add this to your ability_logic if you want all logged in users to be able
    # to submit content
    def everyone_can_create_curation_concerns
      return unless registered_user?
      can :create, curation_concerns_models
    end

    def uploaded_file_abilities
      return unless registered_user?
      can :create, [UploadedFile, BatchUploadItem]
      can :destroy, UploadedFile, user: current_user
      # BatchUploadItem permissions depend on the kind of objects being made by the batch,
      # but it must be authorized directly in the controller, not here.
      # Note: cannot call `authorized_models` without going recursive.
    end

    def proxy_deposit_abilities
      if Flipflop.transfer_works?
        can :transfer, String do |id|
          user_is_depositor?(id)
        end
      end

      can :create, ProxyDepositRequest if (Flipflop.proxy_deposit? || Flipflop.transfer_works?) && registered_user?

      can :accept, ProxyDepositRequest, receiving_user_id: current_user.id, status: 'pending'
      can :reject, ProxyDepositRequest, receiving_user_id: current_user.id, status: 'pending'
      # a user who sent a proxy deposit request can cancel it if it's pending.
      can :destroy, ProxyDepositRequest, sending_user_id: current_user.id, status: 'pending'
    end

    def user_abilities
      can [:edit, :update, :toggle_trophy], ::User, id: current_user.id
      can :show, ::User
    end

    def featured_work_abilities
      can [:create, :destroy, :update], FeaturedWork if admin?
    end

    def editor_abilities
      can :read, ContentBlock
      return unless admin?

      can :read, :admin_dashboard
      can :update, ContentBlock
      can :edit, ::SolrDocument
    end

    def stats_abilities
      can :read, Hyrax::Statistics if admin?
      alias_action :stats, to: :read
    end

    def citation_abilities
      alias_action :citation, to: :read
    end

    def feature_abilities
      can :manage, Hyrax::Feature if admin?
    end

    def operation_abilities
      can :read, Hyrax::Operation, user_id: current_user.id
    end

    # We check based on the depositor, because the depositor may not have edit
    # access to the work if it went through a mediated deposit workflow that
    # removes edit access for the depositor.
    def trophy_abilities
      can [:create, :destroy], Trophy do |t|
        doc = Hyrax::SolrService.search_by_id(t.work_id, fl: 'depositor_ssim')
        current_user.user_key == doc.fetch('depositor_ssim').first
      end
    end

    def curation_concerns_permissions
      # user can version if they can edit
      alias_action :versions, to: :update
      alias_action :file_manager, to: :update

      return if admin?
      cannot :index, Hydra::AccessControls::Embargo
      cannot :index, Hydra::AccessControls::Lease
    end

    def admin_permissions
      return unless admin?
      # TODO: deprecate this. We no longer have a dashboard just for admins
      can :read, :admin_dashboard
      alias_action :edit, to: :update
      alias_action :show, to: :read
      alias_action :discover, to: :read
      can :update, :appearance
      can :manage, String # The identifier of a work or FileSet
      can :manage, curation_concerns_models
      can :manage, Sipity::WorkflowResponsibility
      can :manage, :collection_types
    end

    # TODO: elr - How is this used?  How does it fit with collection participants?
    def add_to_collection
      return unless registered_user?
      alias_action :files, to: :read # members will be filtered separately
      can :collect, :all
    end

    def registered_user?
      return false if current_user.guest?
      user_groups.include? registered_group_name
    end

    # Returns true if the current user is the depositor of the specified work
    # @param document_id [String] the id of the document.
    def user_is_depositor?(document_id)
      Hyrax::WorkRelation.new.search_with_conditions(
        id: document_id,
        DepositSearchBuilder.depositor_field => current_user.user_key
      ).any?
    end

    def curation_concerns_models
      [::FileSet, ::Collection] + Hyrax.config.curation_concerns
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
  end
end
