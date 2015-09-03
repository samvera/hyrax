module CurationConcerns
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:curation_concerns_permissions]
    end

    def curation_concerns_permissions
      unless current_user.new_record?
        can :create, CurationConcerns::ClassifyConcern
      end

      # user can version if they can edit
      alias_action :versions, to: :update

      admin_permissions if admin?

      can :collect, :all
    end

    def admin_permissions
      can [:create, :discover, :show, :read, :edit, :update, :destroy], :all
    end

    def admin?
      user_groups.include? 'admin'
    end

    # Add this to your ability_logic if you want all logged in users to be able
    # to submit content
    def everyone_can_create_curation_concerns
      return if current_user.new_record?
      can :create, [::GenericFile, ::Collection]
      can :create, [CurationConcerns.config.curation_concerns]
    end
  end
end
