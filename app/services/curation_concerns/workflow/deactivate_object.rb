module CurationConcerns
  module Workflow
    ##
    # This is a built in function for workflow, setting the `#state`
    # of the target to the Fedora 'inactive' status URI
    #
    # @param target [#state] an instance of a model that includes `CurationConcerns::Suppressible`
    #
    # @return [RDF::Vocabulary::Term] the Fedora Resource Status 'inactive' term
    class DeactivateObject
      def self.call(target:, **)
        target.state = Vocab::FedoraResourceStatus.inactive
      end
    end
  end
end
