# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Hyrax
  module Transactions
    ##
    # @since 3.0.0
    class Transaction
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      ##
      # @!attribute [rw] container
      #   @return [Container]
      # @!attribute [rw] steps
      #   @return [Array<String>]
      attr_accessor :container, :steps

      ##
      # @param [Container] container
      # @param [Array<String>] steps
      def initialize(container: Container, steps:)
        self.container = container
        self.steps     = steps
      end

      ##
      # @param [Valkyrie::ChangeSet] change_set
      #
      # @return [Dry::Monads::Result]
      def call(change_set)
        Success(
          steps.inject(change_set) do |w, s|
            yield container[s].call(w)
          end
        )
      end
    end
  end
end
