# @deprecated - from the original implementation of UVA's Libra.  This type of behavior should be application-specific.  This will be removed no later than release 6.x
class UserAttribute < ActiveRecord::Base
  belongs_to :user

  def initialize
    ActiveSupport::Deprecation.warn("UserAttribute is deprecated and will be removed from HydraHead in release 5 or 6;  this behavior should be implemented at the app level.")
    super
  end


# Finds the user_attributes based on login
# @param [sting] login the login of the user
# @return the user attribute object or nil
 def self.find_by_login(login)
    ActiveSupport::Deprecation.warn("UserAttribute.find_by_login is deprecated and will be removed from HydraHead in release 5 or 6;  this behavior should be implemented at the app level.")
    user = User.find_by_login(login)
    if user
      UserAttribute.find_by_user_id(user.id)
    else
      nil
    end
  end

# Concatenates first and last name
# @return [string] the first_name + last_name
  def full_name
    fn = first_name.nil? ? "" : first_name
    ln = last_name.nil? ? "" : last_name
    [fn, ln].join(" ").strip
  end

end
