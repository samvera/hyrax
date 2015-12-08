module CurationConcerns
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:curation_concerns_permissions, :add_to_collection]
    end

    def curation_concerns_permissions
      unless current_user.new_record?
        can :create, CurationConcerns::ClassifyConcern
      end

      # user can version if they can edit
      alias_action :versions, to: :update

      if admin?
        admin_permissions
      else
        cannot :index, Hydra::AccessControls::Embargo
        cannot :index, Hydra::AccessControls::Lease
      end
    end

    def admin_permissions
      can [:create, :discover, :show, :read, :edit, :update, :destroy], :all
    end

    def admin?
      user_groups.include? 'admin'
    end

    def add_to_collection
      return if current_user.new_record?
      can :collect, :all
    end

    def registered_user?
      user_groups.include? 'registered'
    end

    # Add this to your ability_logic if you want all logged in users to be able
    # to submit content
    def everyone_can_create_curation_concerns
      return unless registered_user?
      can :create, [::FileSet, ::Collection]
      can :create, [CurationConcerns.config.curation_concerns]
    end
  end
end
