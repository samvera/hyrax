module HydraAccessControlsHelper
  
  # Incomplete.  Currently returns true if user is logged in (regardless of permission level)
  def test_permission(permission_type)
    if !current_user.nil?
      # temporary hack
      if (@document == nil)
        logger.debug("FIXME: SolrDocument is nil")
        return true
      end
      #

      user = current_user.login
      user_groups = RoleMapper.roles(user)
      user_groups.push 'public'
      logger.debug("User #{user} is a member of groups: #{user_groups}")
      result = case permission_type
        when :edit
          logger.debug("Checking edit permissions. user perms: #{Array(RoleMapper.roles(user)).flatten.inspect}, current session user #{user}")
          allowed_edit_groups = @document['edit_access_group_t'] == nil ? [] : @document['edit_access_group_t']
          logger.debug("edit_access_group: #{allowed_edit_groups}")
          group_intersection = user_groups & allowed_edit_groups
          !(group_intersection.empty?) || (@document['edit_access_t'] != nil && @document['edit_access_t'].include?(user))
        when :read
          logger.debug("Checking read permissions. user perms: #{Array(RoleMapper.roles(user)).flatten.inspect}, current session user #{user}")
          allowed_read_groups = @document['read_access_group_t'] == nil ? [] : @document['read_access_group_t']
          logger.debug("read_access_group: #{allowed_read_groups}")
          group_intersection = user_groups & allowed_read_groups
          !(group_intersection.empty?) || (@document['read_access_t'] != nil && @document['read_access_t'].include?(user))
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
