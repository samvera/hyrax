module HydraAccessControlsHelper
  
  # Incomplete.  Currently returns true if user is logged in (regardless of permission level)
  def test_permission(permission_type)
    if !current_user.nil?
      if (@document == nil)
        logger.warn("SolrDocument is nil")
      end

      user = current_user.login
      user_groups = RoleMapper.roles(user)
      # everyone is automatically a member of the group 'public'
      user_groups.push 'public' unless user_groups.include?('public')
      logger.debug("User #{user} is a member of groups: #{user_groups.inspect}")
      case permission_type
        when :edit
          logger.debug("Checking edit permissions for user: #{user}")
          allowed_edit_groups = (@document == nil || @document['edit_access_group_t'] == nil) ? [] : @document['edit_access_group_t']
          logger.debug("  allowed_edit_groups: #{allowed_edit_groups}")
          group_intersection = user_groups & allowed_edit_groups
          allowed_edit_persons = (@document == nil || @document['edit_access_person_t'] == nil) ? [] : @document['edit_access_person_t']
          logger.debug("  allowed_edit_persons: #{allowed_edit_persons}")
          result = !group_intersection.empty? || allowed_edit_persons.include?(user)
        when :read
          logger.debug("Checking read permissions for user: #{user}")
          allowed_read_groups = (@document == nil || @document['read_access_group_t'] == nil) ? [] : @document['read_access_group_t']
          logger.debug("  allowed_read_groups: #{allowed_read_groups}")
          group_intersection = user_groups & allowed_read_groups
          allowed_read_persons = (@document == nil || @document['read_access_person_t'] == nil) ? [] : @document['read_access_person_t']
          result = !group_intersection.empty? || allowed_read_persons.include?(user)
        else
          result = false
      end
      logger.debug("test_permission result: #{result}")
      return result
    else
      logger.debug("nil user, test_permission returning false")
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
