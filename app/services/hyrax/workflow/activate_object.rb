# frozen_string_literal: true
module Hyrax
  module Workflow
    module ActivateObject
      ##
      # This is a built in function for workflow, setting the +#state+
      # of the target to the Fedora +active+ status URI
      #
      # @param target [#state] an instance of a model with a +#state+ property;
      #   e.g. a {Hyrax::Work}
      #
      # @return [RDF::Vocabulary::Term] the Fedora Resource Status 'active' term
      def self.call(target:, **)
        target.state = Hyrax::ResourceStatus::ACTIVE
      end
    end
  end
end
