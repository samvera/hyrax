module CurationConcerns
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:curation_concerns_permissions,
                             :operation_abilities,
                             :add_to_collection]
    end

    def curation_concerns_permissions
      unless current_user.new_record?
        can :create, CurationConcerns::ClassifyConcern
      end

      # user can version if they can edit
      alias_action :versions, to: :update
      alias_action :file_manager, to: :update

      if admin?
        admin_permissions
      else
        cannot :index, Hydra::AccessControls::Embargo
        cannot :index, Hydra::AccessControls::Lease
      end
    end

    def operation_abilities
      can :read, Operation, user_id: current_user.id
    end

    def admin_permissions
      can :read, :admin_dashboard
      alias_action :edit, to: :update
      alias_action :show, to: :read
      alias_action :discover, to: :read

      can :manage, curation_concerns_models
      can :manage, Sipity::WorkflowResponsibility
    end

    # Override this method in your ability model if you use a different group
    # or other logic to designate an administrator.
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
      can :create, curation_concerns_models
    end

    private

      def curation_concerns_models
        [::FileSet, ::Collection] + CurationConcerns.config.curation_concerns
      end
  end
end
