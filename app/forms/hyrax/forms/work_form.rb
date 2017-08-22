# rubocop:disable Metrics/ClassLength
module Hyrax
  module Forms
    # @abstract
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

      # The service that determines the cardinality of each field
      self.field_metadata_service = Hyrax::FormMetadataService

      def initialize(model, current_ability, controller)
        @current_ability = current_ability
        @agreement_accepted = !model.new_record?
        @controller = controller
        super(model)
      end

      # @return [String] an etag representing the current version of this form
      def version
        model.etag
      end

      # The value for some fields should not be set to the defaults ([''])
      # because it should be an empty array instead
      def initialize_field(key)
        return if [:embargo_release_date, :lease_expiration_date].include?(key)
        # rubocop:disable Lint/AssignmentInCondition
        if class_name = model_class.properties[key.to_s].try(:class_name)
          # Initialize linked properties such as based_near
          self[key] += [class_name.new]
        else
          super
        end
        # rubocop:enable Lint/AssignmentInCondition
      end

      # @param [Symbol] key the field to read
      # @return the value of the form field.
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

      # Do not display additional fields if there are no secondary terms
      # @return [Boolean] display additional fields on the form?
      def display_additional_fields?
        secondary_terms.any?
      end

      # @return [Array] a list of works that are members of the primary work on this form.
      def work_members
        model.works
      end

      # Get a list of collection id/title pairs for the select form
      def collections_for_select
        service = Hyrax::CollectionsService.new(@controller)
        CollectionOptionsPresenter.new(service).select_options(:edit)
      end

      # Select collection(s) based on passed-in params
      # @return [Array] a list of collection identifiers
      def member_of_collections(collection_ids)
        Array.wrap(collection_ids)
      end

      # Sanitize the parameters coming from the form. This ensures that the client
      # doesn't send us any more parameters than we expect.
      # In particular we are discarding any access grant parameters for works that
      # are going into a mediated deposit workflow.
      def self.sanitize_params(form_params)
        admin_set_id = form_params[:admin_set_id]
        if admin_set_id && workflow_for(admin_set_id: admin_set_id).allows_access_grant?
          return super
        end
        params_without_permissions = permitted_params.reject { |arg| arg.respond_to?(:key?) && arg.key?(:permissions_attributes) }
        form_params.permit(*params_without_permissions)
      end

      # This describes the parameters we are expecting to receive from the client
      # @return [Array] a list of parameters used by sanitize_params
      def self.build_permitted_params
        super + [
          :on_behalf_of,
          :version,
          :add_works_to_collection,
          {
            work_members_attributes: [:id, :_destroy],
            based_near_attributes: [:id, :_destroy]
          }
        ]
      end

      # TODO: This method should probably move out of this class
      # @param [String] admin_set_id
      # @return Sipity::Workflow the current active workflow for the given AdminSet
      def self.workflow_for(admin_set_id:)
        begin
          workflow = Hyrax::PermissionTemplate.find_by!(admin_set_id: admin_set_id).active_workflow
        rescue ActiveRecord::RecordNotFound
          raise "Missing permission template for AdminSet(id:#{admin_set_id})"
        end
        raise Hyrax::MissingWorkflowError, "PermissionTemplate for AdminSet(id:#{admin_set_id}) does not have an active_workflow" unless workflow
        workflow
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
# rubocop:enable Metrics/ClassLength
