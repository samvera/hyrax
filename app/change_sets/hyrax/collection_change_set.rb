module Hyrax
  class CollectionChangeSet < Valkyrie::ChangeSet
    # Used by the search builder
    attr_accessor :current_ability, :repository

    delegate :id, :depositor, :permissions, to: :model
    class_attribute :member_search_builder_class
    self.member_search_builder_class = Hyrax::CollectionMemberSearchBuilder

    delegate :human_readable_type, :member_ids, :representative_id, :thumbnail_id, to: :model
    property :resource_type, multiple: false, required: false
    property :title, multiple: false, required: true
    property :creator, multiple: true, required: false
    property :contributor, multiple: true, required: false
    property :description, multiple: true, required: false
    property :keyword, multiple: true, required: false
    property :license, multiple: true, required: false
    property :publisher, multiple: true, required: false
    property :date_created, multiple: true, required: false
    property :subject, multiple: true, required: false
    property :language, multiple: true, required: false
    property :identifier, multiple: true, required: false
    property :based_near, multiple: true, required: false
    property :related_url, multiple: true, required: false
    property :visibility, multiple: true, required: false

    validates :title, presence: true

    # @return [Hash] All FileSets in the collection, file.to_s is the key, file.id is the value
    def select_files
      Hash[all_files_with_access]
    end

    # Terms that appear above the accordion
    def primary_terms
      [:title]
    end

    # Terms that appear within the accordion
    def secondary_terms
      [:creator,
       :contributor,
       :description,
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
        @member_search_builder ||= member_search_builder_class.new(self)
      end

      def member_presenters(member_ids)
        PresenterFactory.build_for(ids: member_ids,
                                   presenter_class: WorkShowPresenter,
                                   presenter_args: [nil])
      end
  end
end
