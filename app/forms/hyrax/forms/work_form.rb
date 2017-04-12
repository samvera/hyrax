module Hyrax
  module Forms
    class WorkForm
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      attr_accessor :current_ability

      # This is required so that fields_for will draw a nested form.
      # See ActionView::Helpers#nested_attributes_association?
      #   https://github.com/rails/rails/blob/v5.0.2/actionview/lib/action_view/helpers/form_helper.rb#L1890
      delegate :work_members_attributes=, to: :model
      delegate :human_readable_type, :open_access?, :authenticated_only_access?,
               :open_access_with_embargo_release_date?, :private_access?,
               :embargo_release_date, :lease_expiration_date, :member_ids,
               :visibility, :in_works_ids, :depositor, :on_behalf_of, :permissions,
               :member_of_collection_ids, to: :model

      attr_reader :agreement_accepted

      self.terms = [:title, :creator, :contributor, :description,
                    :keyword, :license, :rights_statement, :publisher, :date_created,
                    :subject, :language, :identifier, :based_near, :related_url,
                    :representative_id, :thumbnail_id, :files,
                    :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                    :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                    :visibility, :ordered_member_ids, :source, :in_works_ids,
                    :member_of_collection_ids, :admin_set_id]

      self.required_fields = [:title, :creator, :keyword, :rights_statement]

      def initialize(model, current_ability, controller)
        @current_ability = current_ability
        @agreement_accepted = !model.new_record?
        @controller = controller
        super(model)
      end

      def version
        model.etag
      end

      # The value for some fields should not be set to the defaults ([''])
      # because it should be an empty array instead
      def initialize_field(key)
        super unless [:embargo_release_date, :lease_expiration_date].include?(key)
      end

      def [](key)
        return model.member_of_collection_ids if key == :member_of_collection_ids
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
           :member_of_collection_ids, :in_works_ids, :admin_set_id]
      end

      def work_members
        model.works
      end

      # Get a list of collection id/title pairs for the select form
      def collections_for_select
        service = Hyrax::CollectionsService.new(@controller)
        CollectionOptionsPresenter.new(service).select_options(:edit)
      end

      # This determines whether the allowed parameters are single or multiple.
      # We are returning true for properties that are backed by methods, for
      # which the HydraEditor::FieldMetadataService cannot determine are multiple.
      # The instance variable is used when choosing which UI widget to draw.
      def multiple?(field)
        Hyrax::FormMetadataService.multiple?(model.class, field)
      end

      # The class method _multiple?_ is used for building the permitted params
      # for the update action
      def self.multiple?(field)
        Hyrax::FormMetadataService.multiple?(model_class, field)
      end

      def self.sanitize_params(form_params)
        admin_set_id = form_params[:admin_set_id]
        if admin_set_id && workflow_for(admin_set_id: admin_set_id).allows_access_grant?
          return super
        end
        params_without_permissions = permitted_params.reject { |arg| arg.respond_to?(:key?) && arg.key?(:permissions_attributes) }
        form_params.permit(*params_without_permissions)
      end

      def self.build_permitted_params
        super + [
          :on_behalf_of,
          :version,
          {
            work_members_attributes: [:id, :_destroy]
          }
        ]
      end

      def self.workflow_for(admin_set_id:)
        Sipity::Workflow.find_by!(id: Hyrax::PermissionTemplate.find_by!(admin_set_id: admin_set_id).active_workflow)
      rescue ActiveRecord::RecordNotFound => e
        raise Hyrax::MissingWorkflowError, e.message
      end
      private_class_method :workflow_for

      private

        # @return [Array<FileSetPresenter>] presenters for the file sets in order of the ids
        def file_presenters
          @file_sets ||=
            Hyrax::PresenterFactory.build_for(ids: model.member_ids,
                                              presenter_class: FileSetPresenter,
                                              presenter_args: current_ability)
        end
    end
  end
end
