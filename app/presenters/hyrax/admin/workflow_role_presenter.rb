module Hyrax
  module Admin
    class WorkflowRolePresenter
      def users
        ::User.registered
      end

      def presenter_for(user)
        agent = user.sipity_agent
        return unless agent
        AgentPresenter.new(agent)
      end

      class AgentPresenter
        def initialize(agent)
          @agent = agent
        end

        def responsibilities_present?
          @agent.workflow_responsibilities.any?
        end

        def responsibilities
          @agent.workflow_responsibilities.each do |responsibility|
            yield ResponsibilityPresenter.new(responsibility)
          end
        end
      end

      class ResponsibilityPresenter
        def initialize(responsibility)
          @responsibility = responsibility
          @wf_role = responsibility.workflow_role
        end

        attr_accessor :responsibility

        delegate :label, to: :@wf_role
      end
    end
  end
end
