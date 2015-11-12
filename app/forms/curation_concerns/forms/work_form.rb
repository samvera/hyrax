module CurationConcerns
  module Forms
    class WorkForm
      include HydraEditor::Form
      attr_accessor :current_ability

      self.terms = [:title, :creator, :contributor, :description,
                    :subject, :publisher, :source, :language,
                    :representative_id, :thumbnail_id, :rights, :files,
                    :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                    :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                    :visibility]

      # @param [ActiveFedora::Base,#member_ids] model
      # @param [Ability] current_ability
      def initialize(model, current_ability)
        @current_ability = current_ability
        super(model)
      end

      # The possible values for the representative_id dropdown
      # @return [Hash] All file sets in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[file_presenters.map { |file| [file.to_s, file.id] }]
      end

      class << self
        # This determines whether the allowed parameters are single or multiple.
        # By default it delegates to the model, but we need to override for
        # 'rights' which only has a single value on the form.
        def multiple?(term)
          case term.to_s
          when 'rights'
            false
          else
            super
          end
        end

        # Overriden to cast 'rights' to an array
        def sanitize_params(form_params)
          super.tap do |params|
            params['rights'] = Array(params['rights']) if params.key?('rights')
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
