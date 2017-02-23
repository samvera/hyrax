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
        @workflow_id || active_workflow.id
      end

      def visibility
        Widgets::AdminSetVisibility.new
      end

      delegate :options, to: :visibility, prefix: :visibility

      def embargo
        Widgets::AdminSetEmbargoPeriod.new
      end

      delegate :options, to: :embargo, prefix: :embargo

      def initialize(model)
        super(model)
        # Ensure proper form options selected, based on model
        select_release_varies_option(model)
      end

        # @return [Hash] { :content_tab (for confirmation message) , :updated (true/false), :error_code (for flash error lookup) }
        def update(attributes)
        return_info = { content_tab: tab_to_update(attributes) }
        update_status = {}
        case return_info[:content_tab]
        when "participants"
          update_status = update_participants_options(attributes)
        when "visibility"
          update_status = update_visibility_options(attributes)
        when "workflow"
          update_status = update_workflow_options(attributes)
        end
        return_info.merge!(update_status)
      end

      private

        # @return [String]
        def tab_to_update(attributes)
          return "participants" if attributes[:access_grants_attributes].present?
          return "workflow" if attributes[:workflow_id].present?
          return "visibility" if attributes.has_key?(:visibility)
        end

        # @return [Hash] { :updated } = true
        def update_participants_options(attributes)
          return_info = {}
          update_admin_set(attributes)
          update_permission_template(attributes)
          return_info[:updated] = true
          return_info
        end

        # @return [Hash] { :error_code - used for flash notice, :updated - true or false}
        def update_visibility_options(attributes)
          return_info = {}
          validated_attributes = validate_visibility_combinations(attributes)
          if validated_attributes[:valid] == true
            update_permission_template(attributes)
          else
            return_info[:error_code] = validated_attributes[:error_code]
          end
          return_info[:updated] = validated_attributes[:valid]
          return_info
        end

        # @return [Hash] { :updated } = true
        def update_workflow_options(attributes)
          return_info = {}
          update_permission_template(attributes)
          grant_workflow_roles(attributes)
          return_info[:updated] = true
          return_info
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

        def update_admin_set(attributes)
          update_params = admin_set_update_params(attributes)
          return unless update_params
          admin_set.tap do |a|
            # We're doing this because ActiveFedora 11.1 doesn't have update!
            # https://github.com/projecthydra/active_fedora/pull/1196
            a.attributes = update_params
            a.save!
          end
        end

        def update_permission_template(attributes)
          model.update(permission_template_update_params(attributes))
        end

        # Maps the raw form attributes into a hash useful for updating the admin set.
        # @return [Hash] includes :edit_users and :edit_groups
        def admin_set_update_params(attributes)
          manage_grants = grants_as_collection(attributes).select { |x| x[:access] == 'manage' }
          return unless manage_grants.present?
          { edit_users: manage_grants.select { |x| x[:agent_type] == 'user' }.map { |x| x[:agent_id] },
            edit_groups: manage_grants.select { |x| x[:agent_type] == 'group' }.map { |x| x[:agent_id] } }
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

        # @return [Hash] attributes used to update the model
        def permission_template_update_params(raw_attributes)
          # Remove release_varies and release_embargo from attributes
          # These form fields are only used to update release_period
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
        # @return [Hash] { error_code: String, valid: true or false }
        def validate_visibility_combinations(attributes)
          # only the visibility tab has validations
          return { valid: true } unless attributes.has_key?(:visibility)

          # if "save" without any selections
          return { error_code: "nothing", valid: false } if !attributes[:release_varies].present? && !attributes[:release_period] && !attributes[:release_date] && !attributes[:release_embargo]

          # if "varies" without sub-options (in this case, release_varies will be missing)
          return { error_code: "varies", valid: false } if attributes[:release_period].blank? && attributes[:release_varies].blank?

          # if "varies before" but date not selected
          return { error_code: "no_date", valid: false } if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE && attributes[:release_date].blank?

          # if "varies with embargo" but no embargo period
          return { error_code: "no_embargo", valid: false } if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO && attributes[:release_embargo].blank?

          # if "fixed" but date not selected
          return { error_code: "no_date", valid: false } if attributes[:release_period] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED && attributes[:release_date].blank?

          { valid: true }
        end
    end
  end
end
