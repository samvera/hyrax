# Injects behaviors into User model so that it will work with Hydra Access Controls
# By default, this module assumes you are using the User model created by Blacklight, which uses Devise.
# To integrate your own User implementation into Hydra, override this Module or define your own User model in app/models/user.rb within your Hydra head.
require 'deprecation'
module Hydra::User
  extend Deprecation
  
  def self.included(klass)
    # Other modules to auto-include
    klass.send(:include, Hydra::SuperuserAttributes)
  end

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against. 
  def user_key
    send(Devise.authentication_keys.first)
  end


  # This method should display the unique identifier for this user
  # the unique identifier is what access controls will be enforced against. 
  def unique_id
    return to_s
  end
  deprecation_deprecate :unique_id

  

  # For backwards compatibility with the Rails2 User models in Hydra/Blacklight
  def login
    return unique_id
  end
  deprecation_deprecate :login
  
end
