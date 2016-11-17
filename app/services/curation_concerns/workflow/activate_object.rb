module CurationConcerns
  module Workflow
    class ActivateObject
      def self.call(target:, **)
        target.state = Vocab::FedoraResourceStatus.active
      end
    end
  end
end
