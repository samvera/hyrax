module HydraAccessControlsHelper
  
  def editor?
    user = session[:user]
    RoleMapper.roles(user).include?("donor") || RoleMapper.roles(user).include?("archivist")
  end
  
  def reader?
    user = session[:user]
    logger.debug("Checking read permissions. user perms: #{Array(RoleMapper.roles(user)).flatten.inspect}, current session user #{session[:user]}")
    RoleMapper.roles(user).include?("donor") || RoleMapper.roles(user).include?("archivist") || RoleMapper.roles(user).include?("researcher") || RoleMapper.roles(user).include?("patron")
  end

end
