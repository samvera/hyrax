# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Hyrax
  module Transactions
    ##
    # Queues up a set of `#steps` to run over a value via `#call`. Steps are
    # given by name, and resolved at runtime via `container`, which defaults to
    # `Hyrax::Transactions::Container`. This allows injection of specific
    # handling for named steps at any time.
    #
    # `#call` will **ALWAYS** return a `Result` (`Success`|`Failure`) and it's
    # recommended for users to handle the output in a way that directly
    # addresses the `Failure` case. The simplest way to do this is to use
    # `#value_or`: `tx.call(my_value).value_or { |failure| handle_failure(f) }`.
    #
    # @since 3.0.0
    #
    # @example running a transaction for a set of steps
    #   steps = ['change_set.validate', 'change_set.save']
    #   tx    = Hyrax::Transactions::Transaction.new(steps: steps)
    #
    #   change_set = Hyrax::ChangeSet.for(Hyrax::Work.new)
    #   change_set.title = ['comet in moominland']
    #
    #   tx.call(change_set) # => Success(#<Hyrax::Work ...>)
    #
    # @example with a failure
    #   class ChangeSetWithTitleValidation < Hyrax::ChangeSet
    #     self.fields = [:title]
    #     validates :title, presence: true
    #   end
    #
    #   change_set = ChangeSetWithTitleValidation.new(Hyrax::Work.new)
    #   change_set.title = []
    #
    #   tx.call(change_set)
    #   # => Failure([:failed_validation, #<Reform::Form::ActiveModel::Errors ...>]
    #
    # @example unwapping values safely with handling for failures
    #   tx.call(change_set).value_or { |failure| "uh oh: #{failure} }
    #
    # @example a pattern for subclassing to create new transactions
    #   class CustomTransaction < Transaction
    #     DEFAULT_STEPS ['step.1', 'step.2', 'step.3']
    #
    #     def initialize(container: Container, steps: DEFAULT_STEPS)
    #       super
    #     end
    #   end
    #
    #   tx = CustomTransaction.new
    #   tx.call(:some_value)
    #
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
      # Run each step name in `#steps` by resolving the name in the given
      # `container` and passing a value to call. Each step must return a
      # `Result`. In the event of a `Success`, the wrapped value is passed
      # through to the next step; for `Failure` the whole chain is short-
      # circuited and the failure result is given.
      #
      # @param [Object] value
      #
      # @return [Dry::Monads::Result] either the `Success` result of the entire
      #   `#steps` chain over `value`, or a `Failure` from the failed step.
      # @see Dry::Monads::Do
      def call(value)
        Success(
          steps.inject(value) do |val, step_name|
            yield container[step_name].call(val)
          end
        )
      end
    end
  end
end
