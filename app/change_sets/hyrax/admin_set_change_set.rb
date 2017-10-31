module Hyrax
  class AdminSetChangeSet < Valkyrie::ChangeSet
    # self.terms = [:title, :description, :thumbnail_id]
    property :title, multiple: false, required: true
    property :description, multiple: true, required: false
    delegate :thumbnail_id, to: :resource

    # Cast any array values on the model to scalars.
    def [](key)
      return super if key == :thumbnail_id
      super.first
    end

    def permission_template
      @permission_template ||= begin
                                 template_model = PermissionTemplate.find_or_create_by(admin_set_id: model.id.to_s)
                                 Forms::PermissionTemplateForm.new(template_model)
                               end
    end

    def thumbnail_title
      return unless thumbnail_id
      Hyrax::Queries.find_by(id: thumbnail_id).title.first
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

    # @return [Hash] All FileSets in the collection, file.to_s is the key, file.id is the value
    def select_files
      Hash[all_files_with_access]
    end

    # Override this method if you have a different way of getting the member's ids
    def member_ids
      Hyrax::Queries.find_inverse_references_by(resource: resource, property: :admin_set_id).map(&:id).map(&:to_s)
    end

    private

      def all_files_with_access
        member_presenters.flat_map(&:file_set_presenters).map { |x| [x.to_s, x.id] }
      end

      def member_presenters
        PresenterFactory.build_for(ids: member_ids,
                                   presenter_class: WorkShowPresenter,
                                   presenter_args: [nil])
      end
  end
end
