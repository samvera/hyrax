module CurationConcerns
  module Workflow
    class ActivateObject
      ##
      # This is a built in function for workflow, setting the `#state`
      # of the target to the Fedora 'active' status URI
      #
      # @param target [#state] an instance of a model that includes `CurationConcerns::Suppressible`
      #
      # @return [RDF::Vocabulary::Term] the Fedora Resource Status 'active' term
      def self.call(target:, **)
        target.state = Vocab::FedoraResourceStatus.active
      end
    end
  end
end
