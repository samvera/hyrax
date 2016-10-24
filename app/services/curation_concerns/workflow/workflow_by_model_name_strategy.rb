module CurationConcerns
  module Workflow
    class WorkflowByModelNameStrategy
      def initialize(work, _attributes)
        @work = work
      end

      # @return [String] The name of the workflow to use
      def workflow_name
        @work.model_name.singular
      end
    end
  end
end
