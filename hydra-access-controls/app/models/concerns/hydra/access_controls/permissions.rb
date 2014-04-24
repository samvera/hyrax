require "deprecation"

module Hydra
  module AccessControls
    module Permissions
      extend ActiveSupport::Concern
      extend Deprecation

      included do
        include Hydra::AccessControls::Visibility
        has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
      end

      ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
      # @example
      #  obj.permissions_attributes= [{:name=>"group1", :access=>"discover", :type=>'group'},
      #  {:name=>"group2", :access=>"discover", :type=>'group'}]
      def permissions_attributes= attributes_collection
        perm_hash = {'person' => rightsMetadata.users, 'group'=> rightsMetadata.groups}

        if attributes_collection.is_a? Hash
          attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
        end

        attributes_collection.each do |row|
          row = row.with_indifferent_access
          if row[:type] == 'user' || row[:type] == 'person'
            if has_destroy_flag? row
              perm_hash['person'].delete(row[:name])
            else
              perm_hash['person'][row[:name]] = row[:access]
            end
          elsif row[:type] == 'group'
            perm_hash['group'][row[:name]] = row[:access]
            if has_destroy_flag? row
              perm_hash['group'].delete(row[:name])
            else
              perm_hash['group'][row[:name]] = row[:access]
            end
          else
            raise ArgumentError, "Permission type must be 'user', 'person' (alias for 'user'), or 'group'"
          end
        end
        
        rightsMetadata.permissions = perm_hash
      end

      ## Returns a list with all the permissions on the object.
      def permissions
        (rightsMetadata.groups.map {|x| Permission.new(type: 'group', access: x[1], name: x[0] )} + 
          rightsMetadata.users.map {|x|  Permission.new(type: 'user', access: x[1], name: x[0] )})
      end

      # @param values [Array<Permission>] a list of permission objects to set
      def permissions= values
        perm_hash = {'person' => {}, 'group'=> {}}
        values.each do |perm|
          if perm.type == 'user'
            perm_hash['person'][perm.name] = perm.access
          else
            perm_hash['group'][perm.name] = perm.access
          end
        end
        rightsMetadata.permissions = perm_hash
      end

      # Return a list of groups that have discover permission
      def discover_groups
        rightsMetadata.groups.map {|k, v| k if v == 'discover'}.compact
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other groups.
      # @param[Array] groups a list of group names
      # @example
      #  r.discover_groups= ['one', 'two', 'three']
      #  r.discover_groups 
      #  => ['one', 'two', 'three']
      #
      def discover_groups=(groups)
        set_discover_groups(groups, discover_groups)
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.discover_groups_string= 'one, two, three'
      #  r.discover_groups 
      #  => ['one', 'two', 'three']
      #
      def discover_groups_string=(groups)
        self.discover_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def discover_groups_string
        self.discover_groups.join(', ')
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for
      # any of the eligible_groups that are not in groups.
      # This may be used when different users are responsible for setting different
      # groups.  Supply the groups the current user is responsible for as the 
      # 'eligible_groups'
      # @param[Array] groups a list of groups
      # @param[Array] eligible_groups the groups that are eligible to have their discover permssion revoked. 
      # @example
      #  r.discover_groups = ['one', 'two', 'three']
      #  r.discover_groups 
      #  => ['one', 'two', 'three']
      #  r.set_discover_groups(['one'], ['three'])
      #  r.discover_groups
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_discover_groups(groups, eligible_groups)
        set_entities(:discover, :group, groups, eligible_groups)
      end

      def discover_users
        rightsMetadata.users.map {|k, v| k if v == 'discover'}.compact
      end

      # Grant discover permissions to the users specified. Revokes discover permission for all other users.
      # @param[Array] users a list of usernames
      # @example
      #  r.discover_users= ['one', 'two', 'three']
      #  r.discover_users 
      #  => ['one', 'two', 'three']
      #
      def discover_users=(users)
        set_discover_users(users, discover_users)
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other users.
      # @param[String] users a list of usernames
      # @example
      #  r.discover_users_string= 'one, two, three'
      #  r.discover_users 
      #  => ['one', 'two', 'three']
      #
      def discover_users_string=(users)
        self.discover_users=users.split(/[\s,]+/)
      end

      # Display the users as a comma delimeted string
      def discover_users_string
        self.discover_users.join(', ')
      end

      # Grant discover permissions to the users specified. Revokes discover permission for
      # any of the eligible_users that are not in users.
      # This may be used when different users are responsible for setting different
      # users.  Supply the users the current user is responsible for as the 
      # 'eligible_users'
      # @param[Array] users a list of users
      # @param[Array] eligible_users the users that are eligible to have their discover permssion revoked. 
      # @example
      #  r.discover_users = ['one', 'two', 'three']
      #  r.discover_users 
      #  => ['one', 'two', 'three']
      #  r.set_discover_users(['one'], ['three'])
      #  r.discover_users
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_discover_users(users, eligible_users)
        set_entities(:discover, :person, users, eligible_users)
      end

      # Return a list of groups that have discover permission
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
        rightsMetadata.users.map {|k, v| k if v == 'read'}.compact
      end

      # Grant read permissions to the users specified. Revokes read permission for all other users.
      # @param[Array] users a list of usernames
      # @example
      #  r.read_users= ['one', 'two', 'three']
      #  r.read_users 
      #  => ['one', 'two', 'three']
      #
      def read_users=(users)
        set_read_users(users, read_users)
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other users.
      # @param[String] users a list of usernames
      # @example
      #  r.read_users_string= 'one, two, three'
      #  r.read_users 
      #  => ['one', 'two', 'three']
      #
      def read_users_string=(users)
        self.read_users=users.split(/[\s,]+/)
      end

      # Display the users as a comma delimeted string
      def read_users_string
        self.read_users.join(', ')
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


      # Return a list of groups that have edit permission
      def edit_groups
        rightsMetadata.groups.map {|k, v| k if v == 'edit'}.compact
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[Array] groups a list of group names
      # @example
      #  r.edit_groups= ['one', 'two', 'three']
      #  r.edit_groups 
      #  => ['one', 'two', 'three']
      #
      def edit_groups=(groups)
        set_edit_groups(groups, edit_groups)
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.edit_groups_string= 'one, two, three'
      #  r.edit_groups 
      #  => ['one', 'two', 'three']
      #
      def edit_groups_string=(groups)
        self.edit_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def edit_groups_string
        self.edit_groups.join(', ')
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for
      # any of the eligible_groups that are not in groups.
      # This may be used when different users are responsible for setting different
      # groups.  Supply the groups the current user is responsible for as the 
      # 'eligible_groups'
      # @param[Array] groups a list of groups
      # @param[Array] eligible_groups the groups that are eligible to have their edit permssion revoked. 
      # @example
      #  r.edit_groups = ['one', 'two', 'three']
      #  r.edit_groups 
      #  => ['one', 'two', 'three']
      #  r.set_edit_groups(['one'], ['three'])
      #  r.edit_groups
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_edit_groups(groups, eligible_groups)
        set_entities(:edit, :group, groups, eligible_groups)
      end

      def edit_users
        rightsMetadata.users.map {|k, v| k if v == 'edit'}.compact
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

      protected 

      def has_destroy_flag?(hash)
        ["1", "true"].include?(hash['_destroy'].to_s)
      end

      private 

      # @param  permission either :discover, :read or :edit
      # @param  type either :person or :group
      # @param  values  Values to set
      # @param  changeable Values we are allowed to change
      def set_entities(permission, type, values, changeable)
        g = preserved(type, permission)
        (changeable - values).each do |entity|
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
          Hash[rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'edit'}]
        when :discover
          Hash[rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'discover'}]
        end
      end

    end
  end
end
