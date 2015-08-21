module CurationConcerns
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:curation_concerns_permissions]
    end

    def curation_concerns_permissions
      unless current_user.new_record?
        can :create, CurationConcerns::ClassifyConcern
        # TODO: Shouldn't this be in `everyone_can_create_curation_concerns` ?
        can :create, ::GenericFile
      end

      if user_groups.include? 'admin'
        can [:create, :discover, :show, :read, :edit, :update, :destroy], :all
      end

      can :collect, :all
    end

    # Add this to your ability_logic if you want all logged in users to be able
    # to submit content
    def everyone_can_create_curation_concerns
      return if current_user.new_record?
      can :create, [CurationConcerns.configuration.curation_concerns]
      can :create, ::Collection
    end
  end
end
