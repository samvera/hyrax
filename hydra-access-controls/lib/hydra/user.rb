# Injects behaviors into User model so that it will work with Hydra Access Controls
# By default, this module assumes you are using the User model created by Blacklight, which uses Devise.
# To integrate your own User implementation into Hydra, override this Module or define your own User model in app/models/user.rb within your Hydra head.
require 'deprecation'
module Hydra::User
  extend Deprecation
  
  def self.included(klass)
    # Other modules to auto-include
    klass.extend(ClassMethods)
  end

  # This method should display the unique identifier for this user as defined by devise.
  # The unique identifier is what access controls will be enforced against. 
  def user_key
    send(Devise.authentication_keys.first)
  end
  
  module ClassMethods
    # This method should find User objects using the user_key you've chosen.
    # By default, uses the unique identifier specified in by devise authentication_keys (ie. find_by_id, or find_by_email).  
    # You must have that find method implemented on your user class, or must override find_by_user_key
    def find_by_user_key(key)
      self.send("find_by_#{Devise.authentication_keys.first}".to_sym, key)
    end
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
