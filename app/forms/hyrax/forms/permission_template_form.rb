module Hyrax
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form

      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :release_date, :release_period, :visibility, to: :model
      delegate :available_workflows, :active_workflow, :admin_set, to: :model

      # @return [#to_s] the primary key of the associated admin_set
      # def admin_set_id (because you might come looking for this method)
      delegate :id, to: :admin_set, prefix: :admin_set

      # Stores which radio button under release "Varies" option is selected
      attr_accessor :release_varies
      # Selected release embargo timeframe (if any) under release "Varies" option
      attr_accessor :release_embargo

      # Stores the selected
      attr_writer :workflow_id

      def workflow_id
        @workflow_id || active_workflow.try(:id)
      end

      def visibility_options
        Widgets::AdminSetVisibility.new.options
      end

      def embargo_options
        Widgets::AdminSetEmbargoPeriod.new.options
      end

      def initialize(model)
        super(model)
        # Ensure proper form options selected, based on model
        select_release_varies_option(model)
      end

      # @return [Hash{Symbol => String, Boolean}] { :content_tab (for confirmation message),
      #                                             :updated (true/false),
      #                                               :error_code (for flash error lookup) }
      def update(attributes)
        return_info = { content_tab: tab_to_update(attributes) }
        error_code = nil
        case return_info[:content_tab]
        when "participants"
          update_participants_options(attributes)
        when "visibility"
          error_code = update_visibility_options(attributes)
        when "workflow"
          grant_workflow_roles(attributes)
        end
        return_info[:error_code] = error_code if error_code
        return_info[:updated] = error_code ? false : true
        return_info
      end

      # If management roles have been granted or removed, then copy this access
      # to the edit permissions of the AdminSet and to the WorkflowResponsibilities
      # of the active workflow
      def update_management
        admin_set.update_access_controls!
        update_workflow_approving_responsibilities
      end

      private

        # @return [String]
        def tab_to_update(attributes)
          return "participants" if attributes[:access_grants_attributes].present?
          return "workflow" if attributes[:workflow_id].present?
          return "visibility" if attributes.key?(:visibility)
        end

        # @return [Void]
        def update_participants_options(attributes)
          update_permission_template(attributes)
          # if managers were added, recalculate update the access controls on the AdminSet
          return unless managers_updated?(attributes)
          update_management
        end

        # Grant workflow approve roles for any admin set managers
        # and revoke the approving role for non-managers
        def update_workflow_approving_responsibilities
          return unless active_workflow
          approving_role = Sipity::Role.find_by_name('approving')
          return unless approving_role
          active_workflow.update_responsibilities(role: approving_role, agents: manager_agents)
        end

        # @return [Array<Sipity::Agent>] a list of sipity agents corresponding to the manager role of the permission_template
        def manager_agents
          @manager_agents ||= begin
            authorized_agents = manager_grants.map do |access|
              if access.agent_type == 'user'
                ::User.find_by_user_key(access.agent_id)
              else
                Hyrax::Group.new(access.agent_id)
              end
            end
            authorized_agents.map { |agent| PowerConverter.convert_to_sipity_agent(agent) }
          end
        end

        # @return [Array<PermissionTemplateAccess>] a list of grants corresponding to the manager role of the permission_template
        def manager_grants
          model.access_grants.where(access: 'manage'.freeze)
        end

        # @return [String, Nil] error_code if validation fails, nil otherwise
        def update_visibility_options(attributes)
          error_code = validate_visibility_combinations(attributes)
          return error_code if error_code
          update_permission_template(attributes)
        end

        def activate_workflow_from(attributes)
          new_active_workflow_id = attributes[:workflow_id] || attributes['workflow_id']
          if active_workflow
            return active_workflow if new_active_workflow_id.to_s == active_workflow.id.to_s
            Sipity::Workflow.activate!(permission_template: model, workflow_id: new_active_workflow_id)
          elsif new_active_workflow_id
            Sipity::Workflow.activate!(permission_template: model, workflow_id: new_active_workflow_id)
          end
        end

        # If the workflow has been changed, ensure that all the AdminSet managers
        # have all the roles for the new workflow
        # @return [Void]
        # @todo Instead of granting the manage users all of the roles (which means lots of emails), can we agree on a Managing role that all workflows should have?
        def grant_workflow_roles(attributes)
          new_active_workflow = activate_workflow_from(attributes)
          return unless new_active_workflow
          model.access_grants.select { |g| g.access == 'manage' }.each do |grant|
            agent = case grant.agent_type
                    when 'user'
                      ::User.find_by_user_key(grant.agent_id)
                    when 'group'
                      Hyrax::Group.new(grant.agent_id)
                    end
            active_workflow.workflow_roles.each do |role|
              Sipity::WorkflowResponsibility.find_or_create_by!(workflow_role: role, agent: agent.to_sipity_agent)
            end
          end
        end

        # @return [Nil]
        def update_permission_template(attributes)
          model.update(permission_template_update_params(attributes))
          nil
        end

        def managers_updated?(attributes)
          grants_as_collection(attributes).any? { |x| x[:access] == 'manage' }
        end

        # This allows the attributes
        def grants_as_collection(attributes)
          return [] unless attributes[:access_grants_attributes]
          attributes_collection = attributes[:access_grants_attributes]
          if attributes_collection.respond_to?(:permitted?)
            attributes_collection = attributes_collection.to_h
          end
          if attributes_collection.is_a? Hash
            attributes_collection = attributes_collection
                                    .sort_by { |i, _| i.to_i }
                                    .map { |_, attrs| attrs }
          end
          attributes_collection
        end

        # In form, select appropriate radio button under Release "Varies" option based on saved permission_template
        def select_release_varies_option(permission_template)
          # Ignore 'no_delay' or 'fixed' values, as they are separate options
          return if permission_template.release_no_delay? || permission_template.release_fixed_date?

          # If embargo specified, then 'embargo' option under "varies" was selected and embargo period selected
          if permission_template.release_max_embargo?
            # If release_period is some other value, it is specifying an embargo period (e.g. 6mos, 1yr, etc)
            @release_varies = Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO
            @release_embargo = permission_template.release_period
          # Else If release_period BEFORE a specified date, then 'before' option under "varies" was selected
          elsif permission_template.release_before_date?
            @release_varies = Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
          end
        end

        # Handles complex defaults
        # Removes release_varies and release_embargo from the returned attributes
        # These form fields are only used to update release_period
        # @return [Hash] attributes used to update the model
        def permission_template_update_params(raw_attributes)
          attributes = raw_attributes.except(:release_varies, :release_embargo)
          # If 'varies' before date option selected, then set release_period='before' and save release_date as-is
          if raw_attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
            attributes[:release_period] = Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
          # Else if 'varies' + embargo selected, save embargo as the release_period
          elsif raw_attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO &&
                raw_attributes[:release_embargo]
            attributes[:release_period] = raw_attributes[:release_embargo]
            # In an embargo, the release_date should be unspecified as it is based on deposit date
            attributes[:release_date] = nil
          end

          if attributes[:release_period] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY
            # If release is "no delay", a release_date should never be allowed/specified
            attributes[:release_date] = nil
          end

          attributes
        end

        # validate the hash of attributes used to update the visibility tab of the model
        # @param [Hash] attributes
        # @return [String, Nil] the error code if invalid, nil if valid
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/PerceivedComplexity
        def validate_visibility_combinations(attributes)
          return unless attributes.key?(:visibility) # only the visibility tab has validations

          # if "save" without any selections - none of the attributes are present
          return "nothing" if !attributes[:release_varies] && !attributes[:release_period] && !attributes[:release_date] && !attributes[:release_embargo]

          # if "varies" without sub-options (in this case, release_varies will be missing)
          return "varies" if attributes[:release_period].blank? && attributes[:release_varies].blank?

          # if "varies before" but date not selected
          return "no_date" if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE && attributes[:release_date].blank?

          # if "varies with embargo" but no embargo period
          return "no_embargo" if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO && attributes[:release_embargo].blank?

          # if "fixed" but date not selected
          return "no_date" if attributes[:release_period] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED && attributes[:release_date].blank?
        end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end
