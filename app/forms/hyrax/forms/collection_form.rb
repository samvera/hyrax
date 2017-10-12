module Hyrax
  module Forms
    class CollectionForm
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      # Used by the search builder
      attr_accessor :current_ability, :repository

      delegate :id, :depositor, :permissions, to: :model

      # Required for search builder (FIXME)
      alias collection model

      self.model_class = ::Collection
      class_attribute :member_search_builder_class

      self.member_search_builder_class = Hyrax::CollectionMemberSearchBuilder

      delegate :human_readable_type, :member_ids, to: :model
      delegate :blacklight_config, to: Hyrax::CollectionsController

      self.terms = [:resource_type, :title, :creator, :contributor, :description,
                    :keyword, :license, :publisher, :date_created, :subject, :language,
                    :representative_id, :thumbnail_id, :identifier, :based_near,
                    :related_url, :visibility, :collection_type_gid]

      self.required_fields = [:title]

      # @param model [Collection] the collection model that backs this form
      # @param current_ability [Ability] the capabilities of the current user
      # @param repository [Blacklight::Solr::Repository] the solr repository
      def initialize(model, current_ability, repository)
        super(model)
        @current_ability = current_ability
        @repository = repository
      end

      def permission_template
        @permission_template ||= begin
                                   template_model = PermissionTemplate.find_or_create_by(source_id: model.id)
                                   PermissionTemplateForm.new(template_model)
                                 end
      end

      # @return [Hash] All FileSets in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[all_files_with_access]
      end

      # Terms that appear above the accordion
      def primary_terms
        [:title, :description]
      end

      # Terms that appear within the accordion
      def secondary_terms
        [:creator,
         :contributor,
         :keyword,
         :license,
         :publisher,
         :date_created,
         :subject,
         :language,
         :identifier,
         :based_near,
         :related_url,
         :resource_type]
      end

      # Do not display additional fields if there are no secondary terms
      # @return [Boolean] display additional fields on the form?
      def display_additional_fields?
        secondary_terms.any?
      end

      def thumbnail_title
        return unless model.thumbnail
        model.thumbnail.title.first
      end

      private

        def all_files_with_access
          member_presenters(member_work_ids).flat_map(&:file_set_presenters).map { |x| [x.to_s, x.id] }
        end

        # Override this method if you have a different way of getting the member's ids
        def member_work_ids
          response = repository.search(member_search_builder.merge(fl: 'id').query).response
          response.fetch('docs').map { |doc| doc['id'] }
        end

        def member_search_builder
          @member_search_builder ||= member_search_builder_class.new(self, search_includes_models: :both)
        end

        def member_presenters(member_ids)
          PresenterFactory.build_for(ids: member_ids,
                                     presenter_class: WorkShowPresenter,
                                     presenter_args: [nil])
        end
    end
  end
end
