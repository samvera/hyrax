module Hyrax
  class CollectionChangeSet < Valkyrie::ChangeSet
    # Used by the search builder
    attr_accessor :current_ability, :repository

    delegate :id, :depositor, to: :model
    delegate :primary_terms, :secondary_terms, to: :class
    delegate :human_readable_type, :member_ids, to: :model

    property :resource_type, multiple: false, required: false
    property :title, multiple: true, required: true
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
    property :thumbnail_id, multiple: false, required: false
    property :representative_id, multiple: false, required: false
    property :visibility, multiple: false, required: false

    # A list of IDs to perform a batch operation on
    property :batch, virtual: true, multiple: true, required: false
    # What batch operation to perform. Either 'add', 'remove', or 'move'
    property :members, virtual: true, multiple: false, required: false
    # When the batch operation is 'move', what collection to move to:
    property :destination_collection_id, virtual: true, multiple: false, required: false

    collection :permissions, virtual: true

    validates :title, presence: true

    # @return [Hash] All FileSets in the collection, file.to_s is the key, file.id is the value
    def select_files
      Hash[all_files_with_access]
    end

    class << self
      # Combined primary and secondary terms
      def terms
        primary_terms + secondary_terms
      end

      # Terms that appear above the accordion
      def primary_terms
        [:title]
      end

      # Terms that appear within the accordion
      # rubocop:disable Metrics/MethodLength
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
         :resource_type,
         :thumbnail_id,
         :representative_id,
         :visibility]
      end
      # rubocop:enable Metrics/MethodLength
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

    # We just need to respond to this method so that the rails nested form builder will work.
    def permissions_attributes=
      # nop
    end

    private

      def all_files_with_access
        member_presenters(member_work_ids).flat_map(&:file_set_presenters).map { |x| [x.to_s, x.id] }
      end

      # Override this method if you have a different way of getting the member's ids
      def member_work_ids
        Hyrax::Queries.find_inverse_references_by(resource: self, property: :member_of_collection_ids).map(&:id).map(&:to_s)
      end

      def member_presenters(member_ids)
        PresenterFactory.build_for(ids: member_ids,
                                   presenter_class: WorkShowPresenter,
                                   presenter_args: [nil])
      end
  end
end
