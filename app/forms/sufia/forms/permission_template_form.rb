module Sufia
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form
      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :release_date, :release_period, :visibility, to: :model

      # Stores which radio button under release "Varies" option is selected
      attr_accessor :release_varies
      # Selected release embargo timeframe (if any) under release "Varies" option
      attr_accessor :release_embargo

      # Visibility options for permission templates
      def visibility_options
        i18n_prefix = "sufia.admin.admin_sets.form_visibility.visibility"
        # Note: Visibility 'varies' = '' implies no constraints
        [[Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, I18n.t('.everyone', scope: i18n_prefix)],
         ['', I18n.t('.varies', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, I18n.t('.institution', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, I18n.t('.restricted', scope: i18n_prefix)]]
      end

      # Embargo / release period options
      def embargo_options
        i18n_prefix = "sufia.admin.admin_sets.form_visibility.release.varies.embargo"
        [[Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS, I18n.t('.6mos', scope: i18n_prefix)],
         [Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR, I18n.t('.1yr', scope: i18n_prefix)],
         [Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS, I18n.t('.2yrs', scope: i18n_prefix)],
         [Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_3_YEARS, I18n.t('.3yrs', scope: i18n_prefix)]]
      end

      def initialize(model)
        # This is a temporary way to make sure all new PermissionTemplates have
        # a workflow assigned to them. Ultimately we want to expose workflows in
        # the UI and have users choose a workflow for their PermissionTemplate.
        model.workflow_name = 'one_step_mediated_deposit'
        super(model)
        # Ensure proper form options selected, based on model
        select_release_varies_option(model)
      end

      def update(attributes)
        manage_grants = grants_as_collection(attributes).select { |x| x[:access] == 'manage' }
        grant_admin_set_access(manage_grants) if manage_grants.present?
        update_release_attributes(attributes)
        model.update(attributes)
      end

      private

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

        def grant_admin_set_access(manage_grants)
          admin_set = AdminSet.find(model.admin_set_id)
          admin_set.edit_users = manage_grants.select { |x| x[:agent_type] == 'user' }.map { |x| x[:agent_id] }
          admin_set.edit_groups = manage_grants.select { |x| x[:agent_type] == 'group' }.map { |x| x[:agent_id] }
          admin_set.save!
        end

        # In form, select appropriate radio button under Release "Varies" option based on saved permission_template
        def select_release_varies_option(permission_template)
          # Ignore 'no_delay' or 'fixed' values, as they are separate options
          return if permission_template.release_no_delay? || permission_template.release_fixed?

          # If release_period BEFORE a specified date, then 'before' option under "varies" was selected
          if permission_template.release_before_date?
            @release_varies = Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
          # If embargo specified, then 'embargo' option under "varies" was selected and embargo period selected
          elsif permission_template.release_embargo?
            # If release_period is some other value, it is specifying an embargo period (e.g. 6mos, 1yr, etc)
            @release_varies = Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO
            @release_embargo = permission_template.release_period
          end
        end

        # Update attributes based on release options selected (if any).
        def update_release_attributes(attributes)
          # If 'varies' before date option selected, then set release_period='before' and save release_date as-is
          if attributes[:release_varies] == Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
            attributes[:release_period] = Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
          # Else if 'varies' + embargo selected, save embargo as the release_period
          elsif attributes[:release_varies] == Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO && attributes[:release_embargo]
            attributes[:release_period] = attributes[:release_embargo]
            # In an embargo, the release_date should be unspecified as it is based on deposit date
            attributes[:release_date] = nil
          end

          # If release is "no delay", a release_date should never be allowed/specified
          if attributes[:release_period] == Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY
            attributes[:release_date] = nil
          end

          # Remove release_varies and release_embargo from attributes
          # These form fields are only used (above) to update release_period
          attributes.delete(:release_varies)
          attributes.delete(:release_embargo)
        end
    end
  end
end
