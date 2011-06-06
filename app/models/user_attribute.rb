class UserAttribute < ActiveRecord::Base
  belongs_to :user


# Finds the user_attributes based on login
# @param [sting] login the login of the user
# @return the user attribute object or nil
 def self.find_by_login(login)
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
