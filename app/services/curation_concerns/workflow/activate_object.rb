module CurationConcerns
  module Workflow
    class ActivateObject
      def self.call(entity:, **)
        entity.proxy_for.state = Vocab::FedoraResourceStatus.active
      end
    end
  end
end
