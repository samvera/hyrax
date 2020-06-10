# frozen_string_literal: true

module Hyrax
  ##
  # Provides setters and getters for the three most common permission modes:
  #   - :discover
  #   - :edit
  #   - :read
  #
  # @example
  #   my_resource = Hyrax.persister.save(resource: Hyrax::Resource.new)
  #   permissions = PermissionManager.new(resource: my_resource)
  #
  #   permissions.read_users # => []
  #   permissions.read_users = ['a_user_key']
  #   permissions.read_users # => ['a_user_key']
  #   permissions.read_users += ['another_user_key']
  #   permissions.read_users # => ['a_user_key', 'another_user_key']
  #
  #   permissions.acl.permissions
  #   # => #<Set: {#<Hyrax::Permission access_to=#<Valkyrie::ID:0x00 @id="81dc73b1-f244-48a7-9c4c-24c7ef528291"> agent="a_user_key" mode=:read>,
  #           <Hyrax::Permission access_to=#<Valkyrie::ID:0x00 @id="81dc73b1-f244-48a7-9c4c-24c7ef528291"> agent="another_user_key" mode=:read>}>
  #
  #   permissions.read_users = []
  #   permissions.read_users # => []
  #   permissions.acl.permissions # => #<Set: {}>
  #
  #   permissions.acl.save
  #
  # @see Hyrax::VisibilityReader
  # @see Hyrax::VisibilityWriter
  # @see Hyrax::AccessControlList
  # @see Hyrax::AccessControl
  # @see Hyrax::Permission
  class PermissionManager
    DISCOVER = :discover
    EDIT     = :edit
    READ     = :read

    ##
    # @!attribute [rw] acl
    #   @return [Hyrax::AccessControlList]
    attr_accessor :acl

    ##
    # @param resource [Valkyrie::Resource]
    def initialize(resource:, acl_class: Hyrax::AccessControlList)
      self.acl = acl_class.new(resource: resource)
    end

    ##
    # @return [Enumerable<String>]
    def discover_groups
      groups_for(mode: DISCOVER)
    end

    ##
    # @param [Enumerable<#to_s>] groups
    #
    # @return [Enumerable<String>]
    def discover_groups=(groups)
      update_groups_for(mode: DISCOVER, groups: groups)
      discover_groups
    end

    ##
    # @return [Enumerable<String>]
    def discover_users
      users_for(mode: DISCOVER)
    end

    ##
    # @param [Enumerable<#to_s>] users
    #
    # @return [Enumerable<String>]
    def discover_users=(users)
      update_users_for(mode: DISCOVER, users: users)
      discover_users
    end

    ##
    # @return [Enumerable<String>]
    def edit_groups
      groups_for(mode: EDIT)
    end

    ##
    # @param [Enumerable<#to_s>] groups
    #
    # @return [Enumerable<String>]
    def edit_groups=(groups)
      update_groups_for(mode: EDIT, groups: groups)
      edit_groups
    end

    ##
    # @return [Enumerable<String>]
    def edit_users
      users_for(mode: EDIT)
    end

    ##
    # @param [Enumerable<#to_s>] users
    #
    # @return [Enumerable<String>]
    def edit_users=(users)
      update_users_for(mode: EDIT, users: users)
      edit_users
    end

    ##
    # @return [Enumerable<String>]
    def read_groups
      groups_for(mode: READ)
    end

    ##
    # @param [Enumerable<#to_s>] groups
    #
    # @return [Enumerable<String>]
    def read_groups=(groups)
      update_groups_for(mode: READ, groups: groups)
      read_groups
    end

    ##
    # @return [Enumerable<String>]
    def read_users
      users_for(mode: READ)
    end

    ##
    # @param [Enumerable<#to_s>] users
    #
    # @return [Enumerable<String>]
    def read_users=(users)
      update_users_for(mode: READ, users: users)
      read_users
    end

    private

    def groups_for(mode:)
      Enumerator.new do |yielder|
        acl.permissions.each do |permission|
          next unless permission.mode == mode
          next unless permission.agent.starts_with?(Hyrax::Group.name_prefix)
          yielder << permission.agent.gsub(Hyrax::Group.name_prefix, '')
        end
      end
    end

    def update_groups_for(mode:, groups:)
      groups = groups.map(&:to_s)

      acl.permissions.each do |permission|
        next unless permission.mode == mode
        next unless permission.agent.starts_with?(Hyrax::Group.name_prefix)

        group_name = permission.agent.gsub(Hyrax::Group.name_prefix, '')
        next if groups.include?(group_name)

        acl.revoke(mode).from(Group.new(group_name))
      end

      groups.each { |g| acl.grant(mode).to(Group.new(g)) }
    end

    def update_users_for(mode:, users:)
      users = users.map(&:to_s)

      user_objects = users.map do |user|
        ::User.find_by_user_key(user) ||
          raise(ArgumentError, "No user exists for user key: #{user}")
      end

      acl.permissions.each do |permission|
        next unless permission.mode == mode
        next if permission.agent.starts_with?(Hyrax::Group.name_prefix)
        next if users.include? permission.agent

        user_for_existing_permission = ::User.find_by_user_key(permission.agent)
        acl.revoke(mode).from(user_for_existing_permission) if user_for_existing_permission
      end

      user_objects.each { |u| acl.grant(mode).to(u) }
    end

    def users_for(mode:)
      Enumerator.new do |yielder|
        acl.permissions.each do |permission|
          next unless permission.mode == mode
          next if permission.agent.starts_with?(Hyrax::Group.name_prefix)
          yielder << permission.agent
        end
      end
    end
  end
end
