class Ability
  include Hydra::Ability 
  
  # Define any customized permissions here.  Some commented examples are included below.
  def custom_permissions

    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end

  end

end
