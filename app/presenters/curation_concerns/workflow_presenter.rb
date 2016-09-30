module CurationConcerns
  class WorkflowPresenter
    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    attr_reader :solr_document, :current_ability

    def state
      sipity_entity.workflow_state_name if sipity_entity
    end

    # TODO: maybe i18n here?
    def state_label
      state
    end

    # Returns an array of tuples (key, label) appropriate for a radio group
    def actions
      return [] unless sipity_entity && current_ability
      actions = CurationConcerns::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(entity: sipity_entity, user: current_ability.current_user)
      actions.map { |action| [action.name, action_label(action)] }
    end

    def comments
      return [] unless sipity_entity
      sipity_entity.comments
    end

    private

      def action_label(action)
        I18n.t("curation_concerns.workflow.#{action.workflow.name}.#{action.name}", default: action.name.titleize)
      end

      def sipity_entity
        PowerConverter.convert(solr_document, to: :sipity_entity)
      rescue PowerConverter::ConversionError
        nil
      end
  end
end
