# Injects behaviors into User model so that it will work with Hydra Access Controls
# By default, this module assumes you are using the User model created by Blacklight, which uses Devise.
# To integrate your own User implementation into Hydra, override this Module or define your own User model in app/models/user.rb within your Hydra head.
module Hydra::User
  extend ActiveSupport::Concern
  include Blacklight::AccessControls::User
  
  included do
    class_attribute :group_service
    self.group_service = RoleMapper
  end

  def groups
    group_service.fetch_groups(user: self)
  end
  
  module ClassMethods
    # This method finds User objects using the user_key as specified by the
    # Devise authentication_keys configuration variable. This method encapsulates
    # whether we use email or username (or something else) as the identifing user attribute.
    def find_by_user_key(key)
      find_by(Hydra.config.user_key_field => key)
    end
  end
end
