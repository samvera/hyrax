module CurationConcerns
  module Workflow
    class ActivateObject
      # See https://github.com/bbatsov/rubocop/issues/3130
      def self.call(entity:, **)
        entity.proxy_for.state = Vocab::FedoraResourceStatus.active
      end
    end
  end
end
