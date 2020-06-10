# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # ACLs for `Hyrax::Resource` models
  #
  # Allows managing `Hyrax::Permission` entries referring to a specific
  # `Hyrax::Resource` using a simple add/delete model.
  #
  # @example Using the Grant DSL
  #   my_resource = Hyrax.query_service.find_by(id: 'my_id')
  #
  #   acl = Hyrax::AccessControlList.new(resource: resource)
  #   acl.permissions # => #<Set: {}>
  #
  #   user  = User.first
  #   group = Group.new('public')
  #
  #   acl.grant(:read).to(group)
  #   acl.grant(:edit).to(user)
  #
  #   acl.permissions
  #   # => #<Set: {#<Hyrax::Permission access_to=#<Valkyrie::ID:0x000055628b0ae0b8 @id="my_id"> agent="group/public" mode=:read>,
  #     #<Hyrax::Permission access_to=#<Valkyrie::ID:0x000055628be41388 @id="my_id"> agent="user1@example.com" mode=:edit>}>
  #
  #   acl.revoke(:edit).from(user)
  #
  #   acl.permissions
  #   # => #<Set: {#<Hyrax::Permission access_to=#<Valkyrie::ID:0x000055628b0ae0b8 @id="my_id"> agent="group/public" mode=:read>}>
  class AccessControlList
    ##
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    # @!attribute [r] persister
    #   @return [#save]
    # @!attribute [r] query_service
    #   @return [#find_inverse_references_by]
    attr_reader :persister, :query_service
    attr_accessor :resource

    ##
    # @api public
    #
    # @param resource [Valkyrie::Resource]
    # @param persister [#save] defaults to the configured Hyrax persister
    # @param query_service [#find_inverse_references_by] defaults to the
    #   configured Hyrax query service
    def initialize(resource:, persister: Hyrax.persister, query_service: Hyrax.query_service)
      self.resource  = resource
      @persister     = persister
      @query_service = query_service
    end

    ##
    # @api public
    #
    # @param permission [Hyrax::Permission]
    #
    # @return [Boolean]
    def <<(permission)
      permission.access_to = resource.id

      change_set.permissions += [permission]

      true
    end
    alias add <<

    ##
    # @api public
    #
    # @param permission [Hyrax::Permission]
    #
    # @return [Boolean]
    def delete(permission)
      change_set.permissions -= [permission]

      true
    end

    ##
    # @api public
    #
    # @example
    #    user = User.find('user_id')
    #
    #    acl.grant(:read).to(user)
    def grant(mode)
      ModeGrant.new(self, mode)
    end

    ##
    # @api public
    #
    # @return [Boolean]
    def pending_changes?
      change_set.changed?
    end

    ##
    # @api public
    #
    # @return [Set<Hyrax::Permission>]
    def permissions
      Set.new(change_set.permissions)
    end

    ##
    # @api public
    #
    # @return [Array<Hyrax::Permission>]
    def permissions=(new_permissions)
      change_set.permissions = new_permissions.to_a
    end

    ##
    # @api public
    #
    # @example
    #    user = User.find('user_id')
    #
    #    acl.revoke(:read).from(user)
    def revoke(mode)
      ModeRevoke.new(self, mode)
    end

    ##
    # @api public
    #
    # Saves the ACL for the resource, by saving each permission policy
    #
    # @return [Boolean]
    def save
      return true unless pending_changes?

      change_set.sync
      persister.save(resource: change_set.resource)
      Hyrax.publisher.publish('object.acl.updated', acl: self, result: :success)
      @change_set = nil

      true
    end

    private

    ##
    # @abstract
    # @api private
    class ModeEditor
      def initialize(acl, mode)
        @acl  = acl
        @mode = mode.to_sym
      end

      private

      def id_for(agent: user_or_group)
        case agent
        when Hyrax::Group
          "#{Hyrax::Group.name_prefix}#{agent.name}"
        else
          agent.user_key.to_s
        end
      end
    end

    ##
    # @api private
    #
    # A short-term memory object for the permission granting DSL. Use with
    # method chaining, as in: `acl.grant(:edit).to(user)`.
    class ModeGrant < ModeEditor
      ##
      # @api public
      # @return [Hyrax::AccessControlList]
      def to(user_or_group)
        agent_id = id_for(agent: user_or_group)

        @acl << Hyrax::Permission.new(access_to: @acl.resource.id, agent: agent_id, mode: @mode)
        @acl
      end
    end

    ##
    # @api private
    #
    # A short-term memory object for the permission revoking DSL. Use with
    # method chaining, as in: `acl.revoke(:edit).from(user)`.
    class ModeRevoke < ModeEditor
      ##
      # @api public
      # @return [Hyrax::AccessControlList]
      def from(user_or_group)
        permission_for_deletion = @acl.permissions.find do |p|
          p.mode == @mode &&
            p.agent.to_s == id_for(agent: user_or_group)
        end

        @acl.delete(permission_for_deletion) if permission_for_deletion
        @acl
      end
    end

    ##
    # @api private
    def access_control_model
      AccessControl.for(resource: resource, query_service: query_service)
    end

    ##
    # @api private
    def change_set
      @change_set ||= Hyrax::ChangeSet.for(access_control_model)
    end
  end
end
