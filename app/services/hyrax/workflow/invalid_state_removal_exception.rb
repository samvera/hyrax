# frozen_string_literal: true
module Hyrax
  module Workflow
    class InvalidStateRemovalException < ::RuntimeError
      attr_reader :states
      def initialize(message, states)
        super(message)
        @states = states
      end
    end
  end
end
