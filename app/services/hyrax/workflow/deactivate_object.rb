# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # This is a built in function for workflow, setting the `#state`
    # of the target to the Fedora 'inactive' status URI
    #
    # @param target [#state] an instance of a model that includes `Hyrax::Suppressible`
    #
    # @return [RDF::Vocabulary::Term] the Fedora Resource Status 'inactive' term
    module DeactivateObject
      def self.call(target:, **)
        target.state = Vocab::FedoraResourceStatus.inactive
      end
    end
  end
end
