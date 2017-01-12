module Hyrax
  module Workflow
    class InvalidStateRemovalException < ::RuntimeError
      attr_reader :state

      def initialize(message, state)
        super(message)
        @state = state
      end
    end
  end
end
