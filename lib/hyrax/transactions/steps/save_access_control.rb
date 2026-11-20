# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves the Hyrax::AccessControlList for any resource with a `#permission_manager`.
      # If `#permission_manager` is undefined, succeeds.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class SaveAccessControl
        include Dry::Monads[:result]

        ##
        # @param [Valkyrie::Resource] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj, permissions_params: [])
          return Success(obj) unless obj.respond_to?(:permission_manager)

          acl = obj.permission_manager&.acl
          apply_params(acl, obj, permissions_params) if acl

          acl&.save || (return Failure[:failed_to_save_acl, acl])

          Success(obj)
        end

        private

        # Each agent's rows are its whole grant. An agent whose rows match its saved levels is
        # skipped, so the form can't undo what an earlier step (an admin set change) did.
        def apply_params(acl, obj, permissions_params)
          saved = Hyrax::AccessControlList.new(resource: obj).permissions
          requested(obj, permissions_params).each do |agent, modes|
            next if modes == levels_for(saved, agent)

            revoke_levels(acl, agent)
            modes.each { |mode| acl << Hyrax::Permission.new(access_to: obj.id, mode: mode, agent: agent) }
          end
        end

        # @return [Hash{String => Set<Symbol>}] the modes each agent should end with
        def requested(obj, permissions_params)
          Array(permissions_params).each_with_object({}) do |param, agents|
            permission = param_to_permission(obj, param)
            next unless permission
            modes = agents[permission.agent] ||= Set.new
            modes << permission.mode unless destroy?(param)
          end
        end

        def destroy?(param)
          ActiveModel::Type::Boolean.new.cast(param["_destroy"])
        end

        def levels
          Hyrax.config.permission_levels.values.map(&:to_sym)
        end

        def levels_for(permissions, agent)
          permissions.select { |p| p.agent == agent && levels.include?(p.mode) }.map(&:mode).to_set
        end

        def revoke_levels(acl, agent)
          acl.permissions
             .select { |p| p.agent == agent && levels.include?(p.mode) }
             .each { |p| acl.delete(p) }
        end

        def param_to_permission(obj, param)
          return nil unless param["access"] && param["type"] && param["name"]
          mode = param["access"].to_sym
          agent = param["type"] == "group" ? "group/#{param['name']}" : param["name"]
          Hyrax::Permission.new(access_to: obj.id, mode: mode, agent: agent)
        end
      end
    end
  end
end
