module HydraAccessControlsHelper
  
  # Incomplete.  Currently returns true if user is logged in (regardless of permission level)
  def test_permission(permission_type)
    if !current_user.nil?
      user = current_user.login
      result = case permission_type
        when :edit
          logger.debug("Checking edit permissions. user perms: #{Array(RoleMapper.roles(user)).flatten.inspect}, current session user #{user}")
          RoleMapper.roles(user).include?("donor") || RoleMapper.roles(user).include?("archivist")
        when :read
          logger.debug("Checking read permissions. user perms: #{Array(RoleMapper.roles(user)).flatten.inspect}, current session user #{user}")
          RoleMapper.roles(user).include?("donor") || RoleMapper.roles(user).include?("archivist") || RoleMapper.roles(user).include?("researcher") || RoleMapper.roles(user).include?("patron")
        else
          false     
      end 
      return result
    else
      return false
    end
  end
  
  def editor?
    test_permission(:edit)
  end
  
  def reader?
   test_permission(:read)
  end

end
