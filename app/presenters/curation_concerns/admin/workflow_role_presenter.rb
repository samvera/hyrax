module CurationConcerns
  module Admin
    class WorkflowRolePresenter
      def users
        ::User.all
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

        def label
          "#{@wf_role.workflow.name} - #{@wf_role.role.name}"
        end
      end
    end
  end
end
