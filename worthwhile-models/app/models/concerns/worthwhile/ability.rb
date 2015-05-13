module Worthwhile
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:worthwhile_permissions]
    end

    def worthwhile_permissions
      
      unless current_user.new_record?
        can :create, Worthwhile::ClassifyConcern
        can :create, [Worthwhile::GenericFile] #, Worthwhile::LinkedResource]
      end

      if user_groups.include? 'admin'
       can [:discover, :show, :read, :edit, :update, :destroy], :all
      end

      can :collect, :all

    end
    
    # Add this to your ability_logic if you want all logged in users to be able to submit content
    def everyone_can_create_curation_concerns
      unless current_user.new_record?
        can :create, [Worthwhile.configuration.curation_concerns]
        #can :create, Collection
      end
    end

  end
end


