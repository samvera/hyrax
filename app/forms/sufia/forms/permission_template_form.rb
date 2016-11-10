module Sufia
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form
      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :visibility, to: :model

      # Visibility options for permission templates
      def visibility_options
        i18n_prefix = "sufia.admin.admin_sets.form_visibility.visibility"
        # Note: Visibility 'varies' = '' implies no constraints
        [[Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, I18n.t('.everyone', scope: i18n_prefix)],
         ['', I18n.t('.varies', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, I18n.t('.institution', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, I18n.t('.restricted', scope: i18n_prefix)]]
      end

      def update(attributes)
        manage_grants = grants_as_collection(attributes).select { |x| x[:access] == 'manage' }
        grant_admin_set_access(manage_grants) if manage_grants.present?
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
    end
  end
end
