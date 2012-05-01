module Dil
  module RightsMetadata
    def read_groups
      rightsMetadata.groups.map {|k, v| k if v == 'read'}.compact
    end

    # Grant read permissions to the groups specified. Revokes read permission for all other groups.
    # @param[Array] groups a list of group names
    # @example
    #  r.read_groups= ['one', 'two', 'three']
    #  r.read_groups 
    #  => ['one', 'two', 'three']
    #
    def read_groups=(groups)
      set_read_groups(groups, read_groups)
    end

    # Grant read permissions to the groups specified. Revokes read permission for all other groups.
    # @param[String] groups a list of group names
    # @example
    #  r.read_groups_string= 'one, two, three'
    #  r.read_groups 
    #  => ['one', 'two', 'three']
    #
    def read_groups_string=(groups)
      self.read_groups=groups.split(/[\s,]+/)
    end

    # Display the groups a comma delimeted string
    def read_groups_string
      self.read_groups.join(', ')
    end

    # Grant read permissions to the groups specified. Revokes read permission for
    # any of the eligible_groups that are not in groups.
    # This may be used when different users are responsible for setting different
    # groups.  Supply the groups the current user is responsible for as the 
    # 'eligible_groups'
    # @param[Array] groups a list of groups
    # @param[Array] eligible_groups the groups that are eligible to have their read permssion revoked. 
    # @example
    #  r.read_groups = ['one', 'two', 'three']
    #  r.read_groups 
    #  => ['one', 'two', 'three']
    #  r.set_read_groups(['one'], ['three'])
    #  r.read_groups
    #  => ['one', 'two']  ## 'two' was not eligible to be removed
    #
    def set_read_groups(groups, eligible_groups)
      set_entities(:read, :group, groups, eligible_groups)
    end

    def read_users
      rightsMetadata.individuals.map {|k, v| k if v == 'read'}.compact
    end

    # Grant read permissions to the groups specified. Revokes read permission for all other groups.
    # @param[Array] users a list of usernames
    # @example
    #  r.read_users= ['one', 'two', 'three']
    #  r.read_users 
    #  => ['one', 'two', 'three']
    #
    def read_users=(users)
      set_read_users(users, read_users)
    end

    # Grant read permissions to the users specified. Revokes read permission for
    # any of the eligible_users that are not in users.
    # This may be used when different users are responsible for setting different
    # users.  Supply the users the current user is responsible for as the 
    # 'eligible_users'
    # @param[Array] users a list of users
    # @param[Array] eligible_users the users that are eligible to have their read permssion revoked. 
    # @example
    #  r.read_users = ['one', 'two', 'three']
    #  r.read_users 
    #  => ['one', 'two', 'three']
    #  r.set_read_users(['one'], ['three'])
    #  r.read_users
    #  => ['one', 'two']  ## 'two' was not eligible to be removed
    #
    def set_read_users(users, eligible_users)
      set_entities(:read, :person, users, eligible_users)
    end

    def edit_users
      rightsMetadata.individuals.map {|k, v| k if v == 'edit'}.compact
    end

    # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
    # @param[Array] users a list of usernames
    # @example
    #  r.edit_users= ['one', 'two', 'three']
    #  r.edit_users 
    #  => ['one', 'two', 'three']
    #
    def edit_users=(users)
      set_edit_users(users, edit_users)
    end

    # Grant edit permissions to the users specified. Revokes edit permission for
    # any of the eligible_users that are not in users.
    # This may be used when different users are responsible for setting different
    # users.  Supply the users the current user is responsible for as the 
    # 'eligible_users'
    # @param[Array] users a list of users
    # @param[Array] eligible_users the users that are eligible to have their edit permssion revoked. 
    # @example
    #  r.edit_users = ['one', 'two', 'three']
    #  r.edit_users 
    #  => ['one', 'two', 'three']
    #  r.set_edit_users(['one'], ['three'])
    #  r.edit_users
    #  => ['one', 'two']  ## 'two' was not eligible to be removed
    #
    def set_edit_users(users, eligible_users)
      set_entities(:edit, :person, users, eligible_users)
    end


    private 

    # @param  permission either :discover, :read or :edit
    # @param  type either :person or :group
    # @param  values  Values to set
    # @param  changeable Values we are allowed to change
    def set_entities(permission, type, values, changable)
      g = preserved(type, permission)
      (changable - values).each do |entity|
        #Strip permissions from users not provided
        g[entity] = 'none'
      end
      values.each { |name| g[name] = permission.to_s}
      rightsMetadata.update_permissions(type.to_s=>g)
    end

    ## Get those permissions we don't want to change
    def preserved(type, permission)
      case permission
      when :edit
        g = {}
      when :read
        rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'edit'}
      when :discover
        rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'discover'}
      end
    end
  end
end

