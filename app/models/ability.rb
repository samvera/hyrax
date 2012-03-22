class Ability
  include CanCan::Ability
  include Hydra::AccessControlsEnforcement

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    user_groups = RoleMapper.roles(user.email)
    # everyone is automatically a member of the group 'public'
    user_groups.push 'public' unless user_groups.include?('public')
    # logged-in users are automatically members of the group "registered"
    user_groups.push 'registered' unless (user == "public" || user_groups.include?('registered') )
    
    logger.debug("Usergroups is " + user_groups.inspect)

    can :edit, String do |pid|
      @response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(pid)
      logger.debug("CANCAN Checking edit permissions for user: #{user}")
      group_intersection = user_groups & edit_groups
      result = !group_intersection.empty? || edit_persons.include?(user.email)
      logger.debug("CANCAN decision: #{result}")
      result
    end 
  
    can :read, String do |pid|
      @response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(pid)
      logger.debug("CANCAN Checking edit permissions for user: #{user}")
      group_intersection = user_groups & read_groups
      result = !group_intersection.empty? || read_persons.include?(user.email)
      logger.debug("CANCAN decision: #{result}")
      result
    end
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
