module CurationConcerns
  module Forms
    class WorkForm
      include HydraEditor::Form
      attr_accessor :current_ability

      self.terms = [:title, :creator, :contributor, :description,
                    :subject, :publisher, :source, :language,
                    :representative_id, :rights, :files,
                    :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                    :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                    :visibility]

      # @param [ActiveFedora::Base,#member_ids] model
      # @param [Ability] current_ability
      def initialize(model, current_ability)
        @model = model
        @current_ability = current_ability
      end

      # The possible values for the representative_id dropdown
      # @return [Hash] All file sets in the collection, file.to_s is the key, file.id is the value
      def files_hash
        Hash[file_presenters.map { |file| [file.to_s, file.id] }]
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
