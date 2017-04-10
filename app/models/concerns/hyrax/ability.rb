module Hyrax
  module Ability
    extend ActiveSupport::Concern

    included do
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
                             :trophy_abilities]
    end

    # Returns true if can create at least one type of work and they can deposit
    # into at least one AdminSet
    def can_create_any_work?
      Hyrax.config.curation_concerns.any? do |curation_concern_type|
        can?(:create, curation_concern_type)
      end && admin_set_ids_for_deposit.any?
    end

    # Override this method in your ability model if you use a different group
    # or other logic to designate an administrator.
    def admin?
      user_groups.include? 'admin'
    end

    # @return [Array<String>] a list of admin set ids for admin sets the user
    #   has deposit or manage permissions to.
    def admin_set_ids_for_deposit
      PermissionTemplateAccess.joins(:permission_template)
                              .where(agent_type: 'user',
                                     agent_id: current_user.user_key,
                                     access: ['deposit', 'manage'])
                              .or(
                                PermissionTemplateAccess.joins(:permission_template)
                                                        .where(agent_type: 'group',
                                                               agent_id: user_groups,
                                                               access: ['deposit', 'manage'])
                              ).pluck('DISTINCT admin_set_id')
    end

    private

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

        if Flipflop.proxy_deposit? && registered_user?
          can :create, ProxyDepositRequest
        end

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
        can :create, TinymceAsset
        can [:create, :update], ContentBlock
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

      def admin_set_abilities
        can :manage, [AdminSet, Hyrax::PermissionTemplate, Hyrax::PermissionTemplateAccess] if admin?

        can [:create, :edit, :update, :destroy], Hyrax::PermissionTemplate do |template|
          test_edit(template.admin_set_id)
        end

        can [:create, :edit, :update, :destroy], Hyrax::PermissionTemplateAccess do |access|
          test_edit(access.permission_template.admin_set_id)
        end

        can :review, :submissions do
          can_review_submissions?
        end
      end

      def operation_abilities
        can :read, Hyrax::Operation, user_id: current_user.id
      end

      # We check based on the depositor, because the depositor may not have edit
      # access to the work if it went through a mediated deposit workflow that
      # removes edit access for the depositor.
      def trophy_abilities
        can [:create, :destroy], Trophy do |t|
          doc = ActiveFedora::Base.search_by_id(t.work_id, fl: 'depositor_ssim')
          current_user.user_key == doc.fetch('depositor_ssim').first
        end
      end

      def curation_concerns_permissions
        can :create, Hyrax::ClassifyConcern if registered_user?

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

        can :manage, curation_concerns_models
        can :manage, Sipity::WorkflowResponsibility
      end

      def add_to_collection
        return unless registered_user?
        can :collect, :all
      end

      def registered_user?
        return false if current_user.guest?
        user_groups.include? 'registered'
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
        # Are there any workflows where this user has the "approving" responsibility
        approving_role = Sipity::Role.find_by(name: 'approving'.freeze)
        return false unless approving_role
        Hyrax::Workflow::PermissionQuery.scope_processing_agents_for(user: current_user).any? do |agent|
          agent.workflow_responsibilities.joins(:workflow_role)
               .where('sipity_workflow_roles.role_id' => approving_role.id).any?
        end
      end
  end
end
