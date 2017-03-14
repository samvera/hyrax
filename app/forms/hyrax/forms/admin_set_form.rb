module Hyrax
  module Forms
    class AdminSetForm < Hyrax::Forms::CollectionForm
      self.model_class = AdminSet
      self.terms = [:title, :description, :thumbnail_id]

      # @param [AdminSet] model
      def initialize(model)
        super(model)
      end

      # Cast any array values on the model to scalars.
      def [](key)
        return super if key == :thumbnail_id
        super.first
      end

      def permission_template
        @permission_template ||= begin
                                   template_model = PermissionTemplate.find_by!(admin_set_id: model.id)
                                   PermissionTemplateForm.new(template_model)
                                 end
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
