module Hyrax
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form

      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :release_date, :release_period, :visibility, :workflow_id, to: :model

      # Stores which radio button under release "Varies" option is selected
      attr_accessor :release_varies
      # Selected release embargo timeframe (if any) under release "Varies" option
      attr_accessor :release_embargo

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

      def update(attributes)
        update_admin_set(attributes)
        update_permission_template(attributes)
        grant_workflow_roles
      end

      def workflows
        # TODO: Scope the workflows only to admin sets see https://github.com/projecthydra-labs/hyrax/issues/256
        Sipity::Workflow.all
      end

      private

        # If the workflow has been changed, ensure that all the AdminSet managers
        # have all the roles for the new workflow
        def grant_workflow_roles
          return unless model.previous_changes.include?("workflow_id")
          workflow = Sipity::Workflow.find_by!(id: model.workflow_id)
          model.access_grants.select { |g| g.access == 'manage' }.each do |grant|
            agent = case grant.agent_type
                    when 'user'
                      ::User.find_by_user_key(grant.agent_id)
                    when 'group'
                      Hyrax::Group.new(grant.agent_id)
                    end
            workflow.workflow_roles.each do |role|
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

        def admin_set
          @admin_set ||= AdminSet.find(model.admin_set_id)
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
    end
  end
end
