module Sufia
  module Ability
    extend ActiveSupport::Concern

    included do
      self.ability_logic += [:sufia_abilities]
    end

    def sufia_abilities
      file_set_abilities
      user_abilities
      featured_work_abilities
      editor_abilities
      stats_abilities
      citation_abilities
      proxy_deposit_abilities
    end

    def proxy_deposit_abilities
      can :transfer, String do |id|
        depositor_for_document(id) == current_user.user_key
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

    def file_set_abilities
      can :view_share_work, [::FileSet]
    end

    def editor_abilities
      can :read, ContentBlock
      return unless admin?

      can :create, TinymceAsset
      can [:create, :update], ContentBlock
    end

    def stats_abilities
      alias_action :stats, to: :read
    end

    def citation_abilities
      alias_action :citation, to: :read
    end

    private

      def depositor_for_document(document_id)
        ::GenericWork.load_instance_from_solr(document_id).depositor
      end
  end
end
