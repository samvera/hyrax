module CurationConcerns
  module Workflow
    # Welcome intrepid developer. You have stumbled into some complex data
    # interactions. There are a lot of data collaborators regarding these tests.
    # I would love this to be more in isolation, but that is not in the cards as
    # there are at least 16 database tables interacting to ultimately answer the
    # following question:
    #
    # * What actions can a given user take on an entity?
    #
    # Could there be more efficient queries? Yes. However, the composition of
    # queries has proven to be a very powerful means of understanding and
    # exploring the problem.
    #
    # @note There is an indication of public or private api. The intent of this
    #   is to differentiate what are methods that are the primary entry points
    #   as understood as of the commit that has the @api tag. However, these are
    #   public methods because they have been tested in isolation and are used
    #   to help compose the `@api public` methods.
    module PermissionQuery
      module_function

      # @api public
      #
      # For the given :user and :entity return only workflow actions that meet all of the following:
      #
      # * available for the :entity's workflow state
      # * permitted to be taken by one or more roles in which the user is assigned
      #   either at the workflow level or the entity level.
      #
      # * Actions to which the user Only actions permitted to the user
      #
      # @param user [User]
      # @param entity [#to_sipity_entity] an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::WorkflowAction>]
      def scope_permitted_workflow_actions_available_for_current_state(user:, entity:)
        workflow_actions_scope = scope_workflow_actions_available_for_current_state(entity: entity)
        workflow_state_actions_scope = scope_permitted_entity_workflow_state_actions(user: user, entity: entity)
        workflow_actions_scope.where(
          workflow_actions_scope.arel_table[:id].in(
            workflow_state_actions_scope.arel_table.project(
              workflow_state_actions_scope.arel_table[:workflow_action_id]
            ).where(workflow_state_actions_scope.constraints.reduce)
          )
        )
      end

      # @api public
      #
      # Agents associated with the given :entity and how they are associated
      # with the given.
      #
      # @param entity [Object] that can be converted into a Sipity::Entity
      # @param role [Object] that can be converted into a Sipity::Role
      # @return [ActiveRecord::Relation<Sipity::Agent>] augmented with
      def scope_agents_associated_with_entity_and_role(entity:, role:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        role = PowerConverter.convert_to_sipity_role(role)
        workflow_roles = Sipity::WorkflowRole.arel_table
        workflow_responsibilities = Sipity::WorkflowResponsibility.arel_table
        entity_responsibilities = Sipity::EntitySpecificResponsibility.arel_table

        agents = Sipity::Agent.arel_table

        agents_select_manager = agents.project(
          :*,
          Arel.sql("'#{Sipity::Agent::ENTITY_LEVEL_AGENT_RELATIONSHIP}'").as('agent_processing_relationship')
        ).where(
          agents[:id].in(
            entity_responsibilities.project(entity_responsibilities[:agent_id]).join(workflow_roles).on(
              workflow_roles[:id].eq(entity_responsibilities[:workflow_role_id])
            ).where(
              entity_responsibilities[:entity_id].eq(entity.id).and(
                workflow_roles[:role_id].eq(role.id)
              )
            )
          )
        ).union(
          agents.project(
            :*,
            Arel.sql("'#{Sipity::Agent::WORKFLOW_LEVEL_AGENT_RELATIONSHIP}'").as('agent_processing_relationship')
          ).where(
            agents[:id].in(
              workflow_responsibilities.project(workflow_responsibilities[:agent_id]).join(workflow_roles).on(
                workflow_roles[:id].eq(workflow_responsibilities[:workflow_role_id])
              ).where(
                workflow_roles[:workflow_id].eq(entity.workflow_id).and(
                  workflow_roles[:role_id].eq(role.id)
                )
              )
            )
          )
        )
        # I would love to use the following:
        #  `Agent.find_by_sql(agents_select_manager.to_sql)`
        #
        # However AREL is adding an opening and closing parenthesis to the query
        # statement. So I needed to massage that output, as follows:
        #
        # ```ruby
        #  Agent.find_by_sql(
        #    agents_select_manager.to_sql.sub(/\A\s*\(\s*(.*)\s*\)\s*\Z/,'\1')
        #  )
        # ```
        #
        # Instead I'm taking an example from:
        # https://github.com/danshultz/mastering_active_record_sample_code/blob/a656c60ca7a2e27b5cd1aadbdf3bdc1814c37000/app/models/beer.rb#L77-L81
        #
        # Note, I'm making a dynamic query with a result the same as the table
        # name of the model that I'm using.
        Sipity::Agent.from(agents.create_table_alias(agents_select_manager, agents.table_name)).all
      end

      # @api public
      #
      # Roles associated with the given :entity
      # @param entity [Object] that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::Role>]
      def scope_roles_associated_with_the_given_entity(entity:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        return Sipity::Role.none unless entity
        workflow_roles = Sipity::WorkflowRole.arel_table
        Sipity::Role.where(
          Sipity::Role.arel_table[:id].in(
            workflow_roles.project(workflow_roles[:role_id]).where(
              workflow_roles[:workflow_id].eq(entity.workflow_id)
            )
          )
        )
      end

      # @api public
      #
      # Is the user authorized to take the processing action on the given
      # entity?
      #
      # @param user [User]
      # @param entity an object that can be converted into a Sipity::Entity
      # @param action an object that can be converted into a Sipity::WorkflowAction#name
      # @return [Boolean]
      def authorized_for_processing?(user:, entity:, action:)
        action_name = PowerConverter.convert_to_sipity_action_name(action)
        scope_permitted_workflow_actions_available_for_current_state(user: user, entity: entity)
          .where(Sipity::WorkflowAction.arel_table[:name].eq(action_name)).count > 0
      end

      # @api public
      #
      # An ActiveRecord::Relation scope that meets the following criteria:
      #
      # * All of the Processing Agents directly associated with the given :user
      #
      # @param user [User]
      # @return [ActiveRecord::Relation<Sipity::Agent>]
      def scope_processing_agents_for(user:)
        return Sipity::Agent.none unless user.present?
        return Sipity::Agent.none unless user.persisted?
        user_agent = PowerConverter.convert_to_sipity_agent(user)
        group_agents = user.groups.map do |g|
          PowerConverter.convert_to_sipity_agent(CurationConcerns::Group.new(g))
        end
        Sipity::Agent.where(id: group_agents + [user_agent])
      end

      PermissionScope = Struct.new(:entity, :workflow)
      private_constant :PermissionScope

      # @api public
      #
      # An ActiveRecord::Relation scope that meets the following criteria:
      #
      # * Sipity::Entity in a state in which I have access to based on:
      #   - The entity specific responsibility
      #     - For which I've been assigned a role
      #   - The workflow specific responsibility
      #     - For which I've been assigned a role
      #
      # @param [User] user
      #
      # @return [ActiveRecord::Relation<Sipity::Entity>]
      def scope_entities_for_the_user(user:)
        entities = Sipity::Entity.arel_table
        workflow_state_actions = Sipity::WorkflowStateAction.arel_table
        workflow_states = Sipity::WorkflowState.arel_table
        workflow_state_action_permissions = Sipity::WorkflowStateActionPermission.arel_table
        workflow_responsibilities = Sipity::WorkflowResponsibility.arel_table
        entity_responsibilities = Sipity::EntitySpecificResponsibility.arel_table

        user_agent_scope = scope_processing_agents_for(user: user)
        user_agent_contraints = user_agent_scope.arel_table.project(
          user_agent_scope.arel_table[:id]
        ).where(user_agent_scope.arel.constraints)

        join_builder = lambda do |responsibility|
          entities.project(
            entities[:id]
          ).join(workflow_state_actions).on(
            workflow_state_actions[:originating_workflow_state_id].eq(entities[:workflow_state_id])
          ).join(workflow_state_action_permissions).on(
            workflow_state_action_permissions[:workflow_state_action_id].eq(workflow_state_actions[:id])
          ).join(workflow_states).on(
            workflow_states[:id].eq(workflow_state_actions[:originating_workflow_state_id])
          ).join(responsibility).on(
            responsibility[:workflow_role_id].eq(workflow_state_action_permissions[:workflow_role_id])
          )
        end

        where_builder = -> (responsibility) { responsibility[:agent_id].in(user_agent_contraints) }

        entity_specific_joins = join_builder.call(entity_responsibilities)
        workflow_specific_joins = join_builder.call(workflow_responsibilities)

        entity_specific_where = where_builder.call(entity_responsibilities).and(
          entities[:id].eq(entity_responsibilities[:entity_id])
        )
        workflow_specific_where = where_builder.call(workflow_responsibilities)

        Sipity::Entity.where(
          entities[:id].in(entity_specific_joins.where(entity_specific_where))
          .or(entities[:id].in(workflow_specific_joins.where(workflow_specific_where)))
        )
      end

      # @api public
      #
      # An ActiveRecord::Relation scope that meets the following criteria:
      #
      # * Users that are directly associated with the given entity through on or
      #   more of the given roles
      # * Users that are indirectly associated with the given entity by group
      #   and role.
      #
      # @param roles [Sipity::Role]
      # @param entity an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<User>]
      def scope_users_for_entity_and_roles(entity:, roles:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        role_ids = Array.wrap(roles).map { |role| PowerConverter.convert_to_sipity_role(role).id }
        user_polymorphic_type = PowerConverter.convert_to_polymorphic_type(::User)

        workflow_roles = Sipity::WorkflowRole.arel_table
        workflow_responsibilities = Sipity::WorkflowResponsibility.arel_table
        entity_responsibilities = Sipity::EntitySpecificResponsibility.arel_table
        user_table = ::User.arel_table
        agent_table = Sipity::Agent.arel_table

        workflow_role_id_subquery = workflow_roles.project(workflow_roles[:id]).where(
          workflow_roles[:role_id].in(role_ids)
        )

        workflow_agent_id_subquery = workflow_responsibilities.project(workflow_responsibilities[:agent_id]).where(
          workflow_responsibilities[:workflow_role_id].in(workflow_role_id_subquery)
        )

        entity_agent_id_subquery = entity_responsibilities.project(entity_responsibilities[:agent_id]).where(
          entity_responsibilities[:workflow_role_id].in(workflow_role_id_subquery)
            .and(entity_responsibilities[:entity_id].eq(entity.id))
        )

        # PostgreSQL requires an explicit cast from string to integer
        cast = Arel::Nodes::NamedFunction.new "CAST", [agent_table[:proxy_for_id].as("integer")]

        sub_query_for_user = agent_table.project(cast).where(
          agent_table[:id].in(workflow_agent_id_subquery)
            .or(agent_table[:id].in(entity_agent_id_subquery))
        ).where(
          agent_table[:proxy_for_type].eq(user_polymorphic_type)
        )

        ::User.where(user_table[:id].in(sub_query_for_user))
      end

      def user_emails_for_entity_and_roles(entity:, roles:)
        scope_users_for_entity_and_roles(entity: entity, roles: roles).pluck(:email)
      end

      # @api public
      #
      # For the given :user and :entity, return an ActiveRecord::Relation that,
      # if resolved, will be all of the assocated workflow roles for both the
      # workflow responsibilities and the entity specific responsibilities.
      #
      # @param user [User]
      # @param entity an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::WorkflowRole>]
      def scope_processing_workflow_roles_for_user_and_entity(user:, entity:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        workflow_scope = scope_processing_workflow_roles_for_user_and_workflow(user: user, workflow: entity.workflow)

        entity_specific_scope = scope_processing_workflow_roles_for_user_and_entity_specific(user: user, entity: entity)
        Sipity::WorkflowRole.where(
          workflow_scope.arel.constraints.reduce.or(entity_specific_scope.arel.constraints.reduce)
        )
      end

      # @api private
      #
      # For the given :user and :workflow, return an ActiveRecord::Relation that,
      # if resolved, will be all of the assocated workflow roles that are
      # assigned to directly to the workflow.
      #
      # @param user [User]
      # @param workflow [Sipity::Workflow]
      # @return [ActiveRecord::Relation<Sipity::WorkflowRole>]
      def scope_processing_workflow_roles_for_user_and_workflow(user:, workflow:)
        responsibility_table = Sipity::WorkflowResponsibility.arel_table
        workflow_role_table = Sipity::WorkflowRole.arel_table

        agent_constraints = scope_processing_agents_for(user: user)
        workflow_role_subquery = workflow_role_table[:id].in(
          responsibility_table.project(responsibility_table[:workflow_role_id])
          .where(
            responsibility_table[:agent_id].in(
              agent_constraints.arel_table.project(
                agent_constraints.arel_table[:id]
              ).where(agent_constraints.arel.constraints)
            )
          )
        )

        Sipity::WorkflowRole.where(
          workflow_role_table[:workflow_id].eq(workflow.id).and(workflow_role_subquery)
        )
      end

      # @api private
      #
      # For the given :user and :entity, return an ActiveRecord::Relation that,
      # if resolved, will be all of the assocated workflow roles that are
      # assigned to specifically to the entity (and not the parent workflow).
      #
      # @param user [User]
      # @param entity an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::WorkflowRole>]
      def scope_processing_workflow_roles_for_user_and_entity_specific(user:, entity:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        agent_scope = scope_processing_agents_for(user: user)
        specific_resp_table = Sipity::EntitySpecificResponsibility.arel_table
        workflow_role_table = Sipity::WorkflowRole.arel_table

        Sipity::WorkflowRole.where(
          workflow_role_table[:id].in(
            specific_resp_table.project(specific_resp_table[:workflow_role_id])
            .where(
              specific_resp_table[:agent_id].in(
                agent_scope.arel_table.project(
                  agent_scope.arel_table[:id]
                ).where(
                  agent_scope.arel.constraints.reduce.and(specific_resp_table[:entity_id].eq(entity.id))
                )
              )
            )
          )
        )
      end

      # @api private
      #
      # For the given :user and :entity, return an ActiveRecord::Relation,
      # that if resolved, will be collection of
      # Sipity::WorkflowStateAction object to which the user has
      # permission to do something.
      #
      # An ActiveRecord::Relation scope that meets the following criteria:
      #
      # * The actions are available for the given entity's current state
      # * The actions are available for the given user based on their role.
      #   Either:
      #   - Directly via an agent associated with a user
      #   - Indirectly via an agent associated with a group
      #
      # @param user [User]
      # @param entity an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::WorkflowStateAction>]
      def scope_permitted_entity_workflow_state_actions(user:, entity:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        workflow_state_actions = Sipity::WorkflowStateAction
        permissions = Sipity::WorkflowStateActionPermission
        role_scope = scope_processing_workflow_roles_for_user_and_entity(user: user, entity: entity)

        workflow_state_actions.where(
          workflow_state_actions.arel_table[:originating_workflow_state_id].eq(entity.workflow_state_id).and(
            workflow_state_actions.arel_table[:id].in(
              permissions.arel_table.project(
                permissions.arel_table[:workflow_state_action_id]
              ).where(
                permissions.arel_table[:workflow_role_id].in(
                  role_scope.arel_table.project(role_scope.arel_table[:id]).where(
                    role_scope.arel.constraints.reduce
                  )
                )
              )
            )
          )
        )
      end

      # @api public
      #
      # For the given :entity return an ActiveRecord::Relation that when
      # resolved will be only the workflow actions that:
      #
      # * Are available for the entity's workflow_state
      #
      # @param entity an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::WorkflowAction>]
      def scope_workflow_actions_for_current_state(entity:)
        entity = PowerConverter.convert_to_sipity_entity(entity)
        state_actions_table = Sipity::WorkflowStateAction.arel_table
        Sipity::WorkflowAction.where(
          Sipity::WorkflowAction.arel_table[:id].in(
            state_actions_table.project(state_actions_table[:workflow_action_id])
              .where(state_actions_table[:originating_workflow_state_id].eq(entity.workflow_state_id))
          )
        )
      end

      # @api private
      #
      # For the given :entity, return an ActiveRecord::Relation, that
      # if resolved, that lists all of the actions available for the entity and
      # its current state.
      #
      # * All actions that are associated with actions that do not have prerequsites
      # * All actions that have prerequisites and all of those prerequisites are complete
      #
      # @param entity an object that can be converted into a Sipity::Entity
      # @return [ActiveRecord::Relation<Sipity::WorkflowAction>]
      def scope_workflow_actions_available_for_current_state(entity:)
        workflow_actions_for_current_state = scope_workflow_actions_for_current_state(entity: entity)
        Sipity::WorkflowAction.where(workflow_actions_for_current_state.constraints.reduce)
      end
    end
  end
end
