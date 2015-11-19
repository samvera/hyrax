# Injects behaviors into User model so that it will work with Hydra Access Controls
# By default, this module assumes you are using the User model created by Blacklight, which uses Devise.
# To integrate your own User implementation into Hydra, override this Module or define your own User model in app/models/user.rb within your Hydra head.
module Hydra::User
  include Blacklight::AccessControls::User
  
  def self.included(klass)
    # Other modules to auto-include
    klass.extend(ClassMethods)
  end

  def groups
    RoleMapper.roles(self)
  end
  
  module ClassMethods
    # This method should find User objects using the user_key you've chosen.
    # By default, uses the unique identifier specified in by devise authentication_keys (ie. find_by_id, or find_by_email).  
    # You must have that find method implemented on your user class, or must override find_by_user_key
    def find_by_user_key(key)
      self.send("find_by_#{Devise.authentication_keys.first}".to_sym, key)
    end
  end
end
