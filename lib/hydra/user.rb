# will move to lib/hydra/access_control folder/namespace in release 5.x
# Injects behaviors into User model so that it will work with Hydra Access Controls
# By default, this module assumes you are using the User model created by Blacklight, which uses Devise.
# To integrate your own User implementation into Hydra, override this Module or define your own User model in app/models/user.rb within your Hydra head.
module Hydra::User
  
  def self.included(klass)
    # Other modules to auto-include
    klass.send(:include, Hydra::SuperuserAttributes)
  end

  # This method should display the unique identifier for this user
  # the unique identifier is what access controls will be enforced against. 
  def unique_id
    return to_s
  end

  # For backwards compatibility with the Rails2 User models in Hydra/Blacklight
  def login
    return unique_id
  end
  
end
