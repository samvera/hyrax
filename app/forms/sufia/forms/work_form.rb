module Sufia
  module Forms
    class WorkForm
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      attr_accessor :current_ability

      # TODO: remove this when https://github.com/projecthydra/hydra-editor/pull/115
      # is merged and hydra-editor 3.0.0 is released
      delegate :model_name, to: :model
      delegate :human_readable_type, :open_access?, :authenticated_only_access?,
               :open_access_with_embargo_release_date?, :private_access?,
               :embargo_release_date, :lease_expiration_date, :member_ids,
               :visibility, :in_works_ids, :depositor, :on_behalf_of, :permissions,
               to: :model

      attr_reader :agreement_accepted
      self.terms = [:title, :creator, :contributor, :description,
                    :keyword, :rights, :publisher, :date_created, :subject, :language,
                    :identifier, :based_near, :related_url,
                    :representative_id, :thumbnail_id, :files,
                    :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                    :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                    :visibility, :ordered_member_ids, :source, :in_works_ids,
                    :collection_ids, :admin_set_id]

      self.required_fields = [:title, :creator, :keyword, :rights]

      def initialize(model, current_ability)
        @current_ability = current_ability
        @agreement_accepted = !model.new_record?
        super(model)
      end

      # The value for embargo_relase_date and lease_expiration_date should not
      # be initialized to empty string
      def initialize_field(key)
        super unless [:embargo_release_date, :lease_expiration_date].include?(key)
      end

      def [](key)
        return model.in_collection_ids if key == :collection_ids
        super
      end

      # The possible values for the representative_id dropdown
      # @return [Hash] All file sets in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[file_presenters.map { |file| [file.to_s, file.id] }]
      end

      # Fields that are automatically drawn on the page above the fold
      def primary_terms
        required_fields
      end

      # Fields that are automatically drawn on the page below the fold
      def secondary_terms
        terms - primary_terms -
          [:files, :visibility_during_embargo, :embargo_release_date,
           :visibility_after_embargo, :visibility_during_lease,
           :lease_expiration_date, :visibility_after_lease, :visibility,
           :thumbnail_id, :representative_id, :ordered_member_ids,
           :collection_ids, :in_works_ids, :admin_set_id]
      end

      # The ordered_members which are FileSet types
      # @return [Array] All of the file sets in the ordered_members
      def ordered_fileset_members
        model.ordered_members.to_a.select { |m| m.model_name.singular.to_sym == :file_set }
      end

      # The ordered_members which are not FileSet types
      # @return [Array] All of the non file sets in the ordered_members
      def ordered_work_members
        model.ordered_members.to_a.select { |m| m.model_name.singular.to_sym != :file_set }
      end

      # This determines whether the allowed parameters are single or multiple.
      # By default it delegates to the model.
      def self.multiple?(term)
        return true if ['rights', 'collection_ids', 'ordered_member_ids', 'in_works_ids'].include? term.to_s
        super
      end

      def self.build_permitted_params
        super + [:on_behalf_of, { collection_ids: [] }]
      end

      # If mediated deposit is indicated, don't allow edit access to be granted to other users.
      def self.sanitize_params(form_params)
        params = super
        return params unless Flipflop.enable_mediated_deposit?
        params.fetch(:permissions_attributes, []).reject! { |attributes| attributes['access'] == 'edit' }
        params
      end

      private

        # @return [Array<FileSetPresenter>] presenters for the file sets in order of the ids
        def file_presenters
          @file_sets ||=
            CurationConcerns::PresenterFactory.build_presenters(model.member_ids, FileSetPresenter, current_ability)
        end
    end
  end
end
