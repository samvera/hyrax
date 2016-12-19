module CurationConcerns
  # Overrides FilterSuppressed filter to hide documents marked as
  # suppressed when the current user is permitted to take no workflow
  # actions for the work's current state
  #
  # Assumes presence of `blacklight_params[:id]` and a SolrDocument
  # corresponding to that `:id` value
  module FilterSuppressedWithRoles
    extend ActiveSupport::Concern
    include CurationConcerns::FilterSuppressed

    # Skip the filter if the current user is permitted to take
    # workflow actions on the work corresponding to the SolrDocument
    # with id = `blacklight_params[:id]`
    def only_active_works(solr_parameters)
      return if user_has_active_workflow_role?
      super
    end

    private

      def current_work
        SolrDocument.find(blacklight_params[:id])
      end

      def user_has_active_workflow_role?
        CurationConcerns::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(user: current_ability.current_user, entity: current_work).any?
      rescue PowerConverter::ConversionError
        # The current_work doesn't have a sipity workflow entity
        false
      end
  end
end
