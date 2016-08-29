module Sufia
  module Forms
    class AdminSetForm
      include HydraEditor::Form
      self.model_class = AdminSet
      self.terms = [:title, :description]
      self.required_fields = [:title]

      # Cast any array values on the model to scalars.
      def [](_key)
        super.first
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
