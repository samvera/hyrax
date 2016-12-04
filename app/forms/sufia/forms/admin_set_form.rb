module Sufia
  module Forms
    class AdminSetForm < CurationConcerns::Forms::CollectionEditForm
      self.model_class = AdminSet
      self.terms = [:title, :description, :thumbnail_id]

      # @param model [AdminSet]
      # @param permission_template [PermissionTemplate]
      def initialize(model, permission_template)
        super(model)
        @permission_template = permission_template
      end

      # Cast any array values on the model to scalars.
      def [](key)
        return super if key == :thumbnail_id
        super.first
      end

      def permission_template
        PermissionTemplateForm.new(@permission_template)
      end

      def workflow_name
        @permission_template.workflow_name
      end

      def workflows
        Sipity::Workflow.all.map { |workflow| [workflow.label, workflow.name] }
      end

      class << self
        # This determines whether the allowed parameters are single or multiple.
        # By default it delegates to the model.
        def multiple?(_term)
          false
        end

        # Overriden to cast 'title' and 'description' to an array
        def sanitize_params(form_params)
          super.tap do |params|
            params['title'] = Array.wrap(params['title']) if params.key?('title')
            params['description'] = Array.wrap(params['description']) if params.key?('description')
          end
        end
      end
    end
  end
end
