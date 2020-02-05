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
    #     DEFAULT_STEPS = ['step.1', 'step.2', 'step.3'].freeze
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
      # @api public
      #
      # @param [Container] container
      # @param [Array<String>] steps
      def initialize(container: Container, steps:)
        self.container = container
        self.steps     = steps
      end

      ##
      # @api public
      #
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
            yield container[step_name].call(val, *step_arguments_for(step_name))
          end
        )
      end

      ##
      # Sets arguments to pass to a given step in the transaction.
      #
      # This makes it easy for individual steps to require pieces of information
      # without other steps having to handle them. This is desirable since it
      # avoids passing mutable values between steps, which commonly results in
      # tight interdependence and less flexible composibility between steps.
      #
      # Instead we expect the caller to provide the correct data to each step
      # when the transaction starts.
      #
      # @param [Hash<Object, Array>] args
      #
      # @return [Transaction] returns self
      #
      # @example passing arguments for a named step
      #   tx = Hyrax::Transactions::Transaction.new(steps: [:first_step, :second_step])
      #   result = tx.with_step_args(second_step: {named_parameter: :param_value}).call(:value)
      #
      def with_step_args(args)
        raise(ArgumentError, key_err_msg(args.keys)) if
          args.keys.any? { |key| !step?(key) }

        @_step_args = args
        self
      end

      private

        ##
        # @api private
        # @param [String, Symbol] step_name
        # @return [Array]
        def step_arguments_for(step_name)
          step_args = @_step_args || {}

          Array.wrap(step_args[step_name])
        end

        ##
        # @api private
        # @param [Array] keys
        # @return [String]
        def key_err_msg(keys)
          missing_steps = keys.select { |key| !step?(key) }

          "Tried to pass step arguments for unknown steps #{missing_steps.join(', ')}\n" \
          "\tSteps defined for this transaction are: #{@steps.join(', ')}"
        end

        ##
        # @api private
        # @param [String, Symbol] step_name
        def step?(step_name)
          steps.include?(step_name)
        end
    end
  end
end
