module Sufia
  module Ability
    extend ActiveSupport::Concern

    included do
      self.ability_logic += [:user_abilities,
                             :featured_work_abilities,
                             :editor_abilities,
                             :stats_abilities,
                             :citation_abilities,
                             :proxy_deposit_abilities,
                             :uploaded_file_abilities,
                             :feature_abilities,
                             :admin_set_abilities]
    end

    def uploaded_file_abilities
      return unless registered_user?
      can :create, [UploadedFile, BatchUploadItem]
      can :destroy, UploadedFile, user: current_user
    end

    def proxy_deposit_abilities
      can :transfer, String do |id|
        user_is_depositor?(id)
      end
      can :create, ProxyDepositRequest if registered_user?
      can :accept, ProxyDepositRequest, receiving_user_id: current_user.id, status: 'pending'
      can :reject, ProxyDepositRequest, receiving_user_id: current_user.id, status: 'pending'
      # a user who sent a proxy deposit request can cancel it if it's pending.
      can :destroy, ProxyDepositRequest, sending_user_id: current_user.id, status: 'pending'
    end

    def user_abilities
      can [:edit, :update, :toggle_trophy], ::User, id: current_user.id
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
      can :read, Sufia::Statistics if admin?
      alias_action :stats, to: :read
    end

    def citation_abilities
      alias_action :citation, to: :read
    end

    def feature_abilities
      can :manage, Sufia::Feature if admin?
    end

    def admin_set_abilities
      can :create, AdminSet if admin?

      can [:create, :edit, :update, :destroy], Sufia::PermissionTemplate do |template|
        test_edit(template.admin_set_id)
      end

      can [:create, :edit, :update, :destroy], Sufia::PermissionTemplateAccess do |access|
        test_edit(access.permission_template.admin_set_id)
      end
    end

    private

      def user_is_depositor?(document_id)
        CurationConcerns::WorkRelation.new.search_with_conditions(
          id: document_id,
          DepositSearchBuilder.depositor_field => current_user.user_key
        ).any?
      end
  end
end
