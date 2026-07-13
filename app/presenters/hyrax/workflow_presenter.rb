# frozen_string_literal: true
module Hyrax
  class WorkflowPresenter
    include ActionView::Helpers::TagHelper

    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    attr_reader :solr_document, :current_ability

    def state
      sipity_entity&.workflow_state_name
    end

    def state_label
      return unless state
      I18n.t("hyrax.workflow.state.#{state}", default: state.humanize)
    end

    # Name of the workflow that drives the draft publication lifecycle.
    DRAFT_WORKFLOW_NAME = 'draft'

    # Returns an array of tuples (key, label) appropriate for a radio group
    def actions
      return [] unless sipity_entity && current_ability
      actions = Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(entity: sipity_entity, user: current_ability.current_user)
      actions = actions.reject { |action| draft_workflow_action?(action) } unless Flipflop.draft_permission?
      actions.map { |action| [action.name, action_label(action)] }
    end

    def comments
      return [] unless sipity_entity
      sipity_entity.comments
    end

    # Name of the draft workflow's promotion action.
    ACTIVATE_ACTION_NAME = 'activate'

    # @return [Boolean] whether the draft promotion action is offered to the
    #   current user, so the view can render the target-visibility picker.
    def draft_activation_available?
      Flipflop.draft_permission? && actions.any? { |key, _| key == ACTIVATE_ACTION_NAME }
    end

    # @return [Array<Array(String, String)>] (label, value) tuples ready for
    #   +options_for_select+ (which expects text first, value second), for the
    #   target-visibility picker shown when promoting a draft.
    def target_visibility_options
      [Hyrax::VisibilityIntention::PUBLIC,
       Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
       Hyrax::VisibilityIntention::PRIVATE].map do |value|
        [I18n.t("hyrax.workflow.draft.target_visibility.#{value}", default: value.titleize), value]
      end
    end

    def badge
      return unless state
      tag.span(state_label, class: "state state-#{state} badge badge-primary")
    end

    private

    # When the +draft_permission+ flag is off, draft-workflow actions are hidden
    # so behavior is identical to installations without the draft lifecycle.
    def draft_workflow_action?(action)
      action.workflow.name == DRAFT_WORKFLOW_NAME
    end

    def action_label(action)
      I18n.t("hyrax.workflow.#{action.workflow.name}.#{action.name}", default: action.name.titleize)
    end

    def sipity_entity
      Sipity::Entity(solr_document)
    rescue Sipity::ConversionError
      nil
    end
  end
end
