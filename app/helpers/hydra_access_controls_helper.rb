module HydraAccessControlsHelper
  
  # Incomplete.  Currently returns true if user is logged in (regardless of permission level)
  def test_permission(permission_type)    
    # if !current_user.nil?
      if (@document == nil)
        logger.warn("SolrDocument is nil")
      end

      if current_user.nil? 
        user = "public"
      else
        user = current_user.login
      end
      
      user_groups = RoleMapper.roles(user)
      # everyone is automatically a member of the group 'public'
      user_groups.push 'public' unless user_groups.include?('public')
      logger.debug("User #{user} is a member of groups: #{user_groups.inspect}")
      case permission_type
        when :edit
          logger.debug("Checking edit permissions for user: #{user}")
          group_intersection = user_groups & edit_groups
          result = !group_intersection.empty? || edit_persons.include?(user)
        when :read
          logger.debug("Checking read permissions for user: #{user}")
          group_intersection = user_groups & read_groups
          result = !group_intersection.empty? || read_persons.include?(user)
        else
          result = false
      end
      logger.debug("test_permission result: #{result}")
      return result
    # else
    #   logger.debug("nil user, test_permission returning false")
    #   return false
    # end
  end
  
  def editor?
    test_permission(:edit)
  end
  
  def reader?
   test_permission(:read)
  end

  private
  def edit_groups
    eg = (@document == nil || @document['edit_access_group_t'] == nil) ? [] : @document['edit_access_group_t']
    logger.debug("edit_groups: #{eg.inspect}")
    return eg
  end

  # edit implies read, so read_groups is the union of edit and read groups
  def read_groups
    rg = edit_groups | ((@document == nil || @document['read_access_group_t'] == nil) ? [] : @document['read_access_group_t'])
    logger.debug("read_groups: #{rg.inspect}")
    return rg
  end

  def edit_persons
    ep = (@document == nil || @document['edit_access_person_t'] == nil) ? [] : @document['edit_access_person_t']
    logger.debug("edit_persons: #{ep.inspect}")
    return ep
  end

  # edit implies read, so read_persons is the union of edit and read persons
  def read_persons
    rp = edit_persons | ((@document == nil || @document['read_access_person_t'] == nil) ? [] : @document['read_access_person_t'])
    logger.debug("read_persons: #{rp.inspect}")
    return rp
  end

end
