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

    # Returns an array of tuples (key, label) appropriate for a radio group
    def actions
      return [] unless sipity_entity && current_ability
      actions = Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(entity: sipity_entity, user: current_ability.current_user)
      actions.map { |action| [action.name, action_label(action)] }
    end

    def comments
      return [] unless sipity_entity
      sipity_entity.comments
    end

    def badge
      return unless state
      tag.span(state_label, class: "state state-#{state} badge badge-primary")
    end

    private

    def action_label(action)
      I18n.t("hyrax.workflow.#{action.workflow.name}.#{action.name}", default: action.name.titleize)
    end

    def sipity_entity
      Sipity::Entity(solr_document)
    rescue PowerConverter::ConversionError
      nil
    end
  end
end
