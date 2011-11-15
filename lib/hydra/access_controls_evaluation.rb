# Provides methods for testing permissions
# If you include this into a Controller, it will also make a number of these methods available as view helpers.
module Hydra::AccessControlsEvaluation
  
  def self.included(klass)
    if klass.respond_to?(:helper_method)
      klass.helper_method(:editor?)
      klass.helper_method(:reader?)
      klass.helper_method(:test_permission?)
    end
  end
  
  # Test the current user's permissions.  This method is used by the editor? and reader? methods
  # @param [Symbol] permission_type valid options: :edit, :read
  # This is available as a view helper method as well as within your controllers.
  # @example
  #   test_permission(:edit)
  def test_permission(permission_type)    
    # if !current_user.nil?
      if (@permissions_solr_document == nil)
        logger.warn("SolrDocument is nil")
      end

      if current_user.nil? 
        user = "public"
        logger.debug("current_user is nil, assigning public")
      else
        user = user_key
      end
      
      user_groups = RoleMapper.roles(user)
      # everyone is automatically a member of the group 'public'
      user_groups.push 'public' unless user_groups.include?('public')
      # logged-in users are automatically members of the group "registered"
      user_groups.push 'registered' unless (user == "public" || user_groups.include?('registered') )
      
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
  
  # Test whether the the current user has edit permissions.  
  # This is available as a view helper method as well as within your controllers.
  def editor?
    test_permission(:edit) or (current_user and current_user.is_being_superuser?(session))
  end
  
  # Test whether the the current user has read permissions.  
  # This is available as a view helper method as well as within your controllers.
  def reader?
    test_permission(:read) or (current_user and current_user.is_being_superuser?(session))
  end

  private
  def edit_groups
    edit_group_field = Hydra.config[:permissions][:edit][:group]
    eg = ((@permissions_solr_document == nil || @permissions_solr_document.fetch(edit_group_field,nil) == nil) ? [] : @permissions_solr_document.fetch(edit_group_field,nil))
    logger.debug("edit_groups: #{eg.inspect}")
    return eg
  end

  # edit implies read, so read_groups is the union of edit and read groups
  def read_groups
    read_group_field = Hydra.config[:permissions][:read][:group]
    rg = edit_groups | ((@permissions_solr_document == nil || @permissions_solr_document.fetch(read_group_field,nil) == nil) ? [] : @permissions_solr_document.fetch(read_group_field,nil))
    logger.debug("read_groups: #{rg.inspect}")
    return rg
  end

  def edit_persons
    edit_person_field = Hydra.config[:permissions][:edit][:individual]
    ep = ((@permissions_solr_document == nil || @permissions_solr_document.fetch(edit_person_field,nil) == nil) ? [] : @permissions_solr_document.fetch(edit_person_field,nil))
    logger.debug("edit_persons: #{ep.inspect}")
    return ep
  end

  # edit implies read, so read_persons is the union of edit and read persons
  def read_persons
    read_individual_field = Hydra.config[:permissions][:read][:individual]
    rp = edit_persons | ((@permissions_solr_document == nil || @permissions_solr_document.fetch(read_individual_field,nil) == nil) ? [] : @permissions_solr_document.fetch(read_individual_field,nil))
    logger.debug("read_persons: #{rp.inspect}")
    return rp
  end

end
