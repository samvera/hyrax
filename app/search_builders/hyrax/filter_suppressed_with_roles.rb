# frozen_string_literal: true
module Hyrax
  # Overrides FilterSuppressed filter to hide documents marked as
  # suppressed when the current user is permitted to take no workflow
  # actions for the work's current state
  #
  # Assumes presence of `blacklight_params[:id]` and a SolrDocument
  # corresponding to that `:id` value
  module FilterSuppressedWithRoles
    extend ActiveSupport::Concern
    include FilterSuppressed

    # Skip the filter if the current user is:
    #
    # *  permitted to take workflow actions on the work
    # *  the depositor
    #
    # corresponding to the SolrDocument with id = `blacklight_params[:id]`
    #
    # @note This is another case in which the Sipity workflows and the
    #       SOLR permissions are not adequately synchronized.  Sipity COULD
    #       be used to include that information, however that is not
    #       presently scoped work.
    def only_active_works(solr_parameters)
      current_work = ::SolrDocument.find(blacklight_params[:id])
      return if user_has_active_workflow_role?(current_work: current_work)
      return if depositor?(current_work: current_work)
      super
    end

    private

    def user_has_active_workflow_role?(current_work:)
      Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(user: current_ability.current_user, entity: current_work).any?
    rescue Sipity::ConversionError
      # The current_work doesn't have a sipity workflow entity
      false
    end

    def depositor?(current_work:)
      depositors = current_work[DepositSearchBuilder.depositor_field]

      return false if depositors.nil?

      depositors.first == current_ability.current_user.user_key
    end
  end
end
