# frozen_string_literal: true

module Hyrax
  ##
  # ACLs for `Hyrax::Resource` models
  #
  # Allows managing `Hyrax::Permission` entries referring to a specific
  # `Hyrax::Resource` using a simple add/delete model.
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
    # @param resource [Valkyrie::Resource]
    # @param persister [#save]
    # @param query_service [#find_inverse_references_by]
    def initialize(resource:, persister: Hyrax.persister, query_service: Hyrax.query_service)
      self.resource  = resource
      @persister     = persister
      @query_service = query_service
    end

    ##
    # @param permission [Hyrax::Permission]
    #
    # @return [Boolean]
    def <<(permission)
      permission.access_to = resource.id

      additions << permission

      true
    end
    alias add <<

    ##
    # @param permission [Hyrax::Permission]
    #
    # @return [Boolean]
    def delete(permission)
      additions.delete(permission)
      deletions << permission

      true
    end

    ##
    # @example
    #    user = User.find('user_id')
    #
    #    acl.grant(:read).to(user)
    def grant(mode)
      ModeGrant.new(self, mode)
    end

    ##
    # @return [Boolean]
    def pending_changes?
      additions.any? || deletions.any?
    end

    ##
    # @return [Enumerable<Hyrax::Permission>]
    def permissions
      Set.new(query_service.find_inverse_references_by(resource: resource, property: :access_to)) -
        deletions |
        additions
    end

    ##
    # @example
    #    user = User.find('user_id')
    #
    #    acl.revoke(:read).from(user)
    def revoke(mode)
      ModeRevoke.new(self, mode)
    end

    ##
    # Saves the ACL for the resource, by saving each permission policy
    #
    # @return [Boolean]
    def save
      return true unless pending_changes?

      deletions.each { |p| persister.delete(resource: p) }
      deletions.clear

      additions.each { |p| persister.save(resource: p) }
      additions.clear

      true
    end

    private

      ##
      # @abstract
      class ModeEditor
        def initialize(acl, mode)
          @acl  = acl
          @mode = mode.to_sym
        end

        private

          def id_for(agent: user_or_group)
            agent.id
          end
      end

      class ModeGrant < ModeEditor
        ##
        # @return [Hyrax::AccessControlList]
        def to(user_or_group)
          agent_id = id_for(agent: user_or_group)

          @acl << Hyrax::Permission.new(access_to: @acl.resource.id, agent: agent_id, mode: @mode)
          @acl
        end
      end

      class ModeRevoke < ModeEditor
        def from(user_or_group)
          permission_for_deletion = @acl.permissions.find do |p|
            p.mode == @mode &&
              p.agent == id_for(agent: user_or_group)
          end

          @acl.delete(permission_for_deletion) if permission_for_deletion
          @acl
        end
      end

      def additions
        @additions ||= Set.new
      end

      def deletions
        @deletions ||= Set.new
      end
  end
end
