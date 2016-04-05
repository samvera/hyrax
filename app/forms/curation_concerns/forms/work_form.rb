module CurationConcerns
  module Forms
    class WorkForm
      include HydraEditor::Form
      attr_accessor :current_ability

      delegate :human_readable_type, :open_access?, :authenticated_only_access?,
               :open_access_with_embargo_release_date?, :private_access?,
               :embargo_release_date, :lease_expiration_date, :member_ids,
               :visibility, to: :model

      self.terms = [:title, :creator, :contributor, :description,
                    :tag, :rights, :publisher, :date_created, :subject, :language,
                    :identifier, :based_near, :related_url,
                    :representative_id, :thumbnail_id, :files,
                    :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                    :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                    :visibility, :ordered_member_ids]

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

      class << self
        # This determines whether the allowed parameters are single or multiple.
        # By default it delegates to the model, but we need to override for
        # 'rights' which only has a single value on the form.
        def multiple?(term)
          case term.to_s
          when 'rights'
            false
          when 'ordered_member_ids'
            true
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
