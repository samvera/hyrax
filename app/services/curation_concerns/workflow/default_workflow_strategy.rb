module CurationConcerns
  module Workflow
    class DefaultWorkflowStrategy
      def initialize(_work, _attributes)
      end

      # @return [String] The name of the workflow to use
      def workflow_name
        'default'
      end
    end
  end
end
