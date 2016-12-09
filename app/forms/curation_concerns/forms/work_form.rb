module CurationConcerns
  module Forms
    class WorkForm
      include HydraEditor::Form
      attr_accessor :current_ability

      delegate :human_readable_type, :open_access?, :authenticated_only_access?,
               :open_access_with_embargo_release_date?, :private_access?,
               :embargo_release_date, :lease_expiration_date, :member_ids,
               :visibility, :in_works_ids, :member_of_collection_ids, to: :model

      self.terms = [:title, :creator, :contributor, :description,
                    :keyword, :rights, :publisher, :date_created, :subject, :language,
                    :identifier, :based_near, :related_url,
                    :representative_id, :thumbnail_id, :files,
                    :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                    :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                    :visibility, :ordered_member_ids, :source, :in_works_ids,
                    :member_of_collection_ids]

      self.required_fields = [:title]

      # @param [ActiveFedora::Base,#member_ids] model
      # @param [Ability] current_ability
      def initialize(model, current_ability)
        @current_ability = current_ability
        super(model)
      end

      # The value for embargo_relase_date and lease_expiration_date should not
      # be initialized to empty string
      def initialize_field(key)
        super unless [:embargo_release_date, :lease_expiration_date].include?(key)
      end

      # The possible values for the representative_id dropdown
      # @return [Hash] All file sets in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[file_presenters.map { |file| [file.to_s, file.id] }]
      end

      # Get a list of collection id/title pairs for the select form
      def collections_for_select
        ::Collection.all.map { |col| [col.first_title, col.id] }
      end

      class << self
        # This determines whether the allowed parameters are single or multiple.
        # By default it delegates to the model.
        def multiple?(term)
          case term.to_s
          when 'ordered_member_ids'
            true
          when 'in_works_ids'
            true
          when 'member_of_collection_ids'
            true
          else
            super
          end
        end
      end

      private

        # @return [Array<FileSetPresenter>] presenters for the file sets in order of the ids
        def file_presenters
          @file_sets ||=
            PresenterFactory.build_presenters(model.member_ids, FileSetPresenter, current_ability)
        end
    end
  end
end
