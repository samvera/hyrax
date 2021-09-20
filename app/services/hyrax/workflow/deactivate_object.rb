# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # This is a built in function for workflow, setting the +#state+
    # of the target to the Fedora +inactive+ status URI
    #
    # @param target [#state] an instance of a model with a +#state+ property;
    #   e.g. a {Hyrax::Work}
    #
    # @return [RDF::URI] the Fedora Resource Status 'inactive' term
    # @see Hyrax::ResourceStatus
    module DeactivateObject
      def self.call(target:, **)
        target.state = Hyrax::ResourceStatus::ACTIVE
      end
    end
  end
end
