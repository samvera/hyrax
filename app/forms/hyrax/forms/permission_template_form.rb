module Hyrax
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form

      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :release_date, :release_period, :visibility, :workflow_name, to: :model

      # Stores which radio button under release "Varies" option is selected
      attr_accessor :release_varies
      # Selected release embargo timeframe (if any) under release "Varies" option
      attr_accessor :release_embargo

      # Visibility options for permission templates
      def visibility_options
        i18n_prefix = "hyrax.admin.admin_sets.form_visibility.visibility"
        # Note: Visibility 'varies' = '' implies no constraints
        [[Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, I18n.t('.everyone', scope: i18n_prefix)],
         ['', I18n.t('.varies', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, I18n.t('.institution', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, I18n.t('.restricted', scope: i18n_prefix)]]
      end

      # Embargo / release period options
      def embargo_options
        i18n_prefix = "hyrax.admin.admin_sets.form_visibility.release.varies.embargo"
        [[Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS, I18n.t('.6mos', scope: i18n_prefix)],
         [Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR, I18n.t('.1yr', scope: i18n_prefix)],
         [Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS, I18n.t('.2yrs', scope: i18n_prefix)],
         [Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_3_YEARS, I18n.t('.3yrs', scope: i18n_prefix)]]
      end

      def initialize(model)
        super(model)
        # Ensure proper form options selected, based on model
        select_release_varies_option(model)
      end

      def update(attributes)
        grant_admin_set_access(attributes)
        model.update(update_release_attributes(attributes))
      end

      def workflows
        # TODO: Scope the workflows only to admin sets see https://github.com/projecthydra-labs/hyrax/issues/256
        Sipity::Workflow.all
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

        def grant_admin_set_access(attributes)
          manage_grants = grants_as_collection(attributes).select { |x| x[:access] == 'manage' }
          return unless manage_grants.present?
          admin_set = AdminSet.find(model.admin_set_id)
          admin_set.edit_users = manage_grants.select { |x| x[:agent_type] == 'user' }.map { |x| x[:agent_id] }
          admin_set.edit_groups = manage_grants.select { |x| x[:agent_type] == 'group' }.map { |x| x[:agent_id] }
          admin_set.save!
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
        def update_release_attributes(raw_attributes)
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
