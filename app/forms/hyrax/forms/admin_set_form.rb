module Hyrax
  module Forms
    class AdminSetForm < Hyrax::Forms::CollectionForm
      self.model_class = AdminSet
      self.terms = [:title, :description, :thumbnail_id]

      # Cast any array values on the model to scalars.
      def [](key)
        return super if key == :thumbnail_id
        if key == :title
          @attributes["title"].each do |value|
            @attributes["alt_title"] << value
          end
          @attributes["alt_title"].delete(@attributes["alt_title"].sort.first) unless @attributes["alt_title"].empty?
          return @attributes["title"].sort.first unless @attributes["title"].empty?
          return ""
        end
        super.first
      end

      def permission_template
        @permission_template ||= begin
                                   template_model = PermissionTemplate.find_or_create_by(source_id: model.id)
                                   PermissionTemplateForm.new(template_model)
                                 end
      end

      def thumbnail_title
        return unless model.thumbnail
        model.thumbnail.title.first
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

      private

        def member_work_ids
          model.member_ids
        end
    end
  end
end
