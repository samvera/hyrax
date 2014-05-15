module Worthwhile
  module Ability
    extend ActiveSupport::Concern
    included do
      self.ability_logic += [:worthwhile_permissions]
    end

    def worthwhile_permissions
      
      unless current_user.new_record?
        can :create, Worthwhile::ClassifyConcern
        can :create, [Worthwhile::GenericFile, Worthwhile::LinkedResource]
      end
      # alias_action :confirm, :copy, :to => :update
# 
#       if user_groups.include? 'admin'
#         can [:discover, :show, :read, :edit, :update, :destroy], :all
#       end
# 
#       # Proxy Deposit -- allow these actions if the asset's owner can_receive_deposits_from current_user 
#       can [:show, :read, :update, :destroy], [Curate.configuration.curation_concerns] do |w|
#         u = ::User.find_by_user_key(w.owner)
#         u && u.can_receive_deposits_from.include?(current_user)
#       end

    end
    
    # Add this to your ability_logic if you want all logged in users to be able to submit content
    def everyone_can_create_curation_concerns
      can :create, [Worthwhile.configuration.curation_concerns]
      can :create, Collection
    end

  end
end


