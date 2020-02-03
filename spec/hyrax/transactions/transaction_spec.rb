# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::Transaction do
  subject(:tx) { described_class.new(steps: step_names) }
  let(:step_names) { ['change_set.validate', 'change_set.apply'] }
  let(:value) { :moomin }

  let(:failure_step) do
    Class.new do # always fails
      include Dry::Monads[:result]

      def call(*args)
        Failure([:always_fails, *args])
      end
    end.new
  end

  let(:success_step) do
    Class.new do # always succeeds
      include Dry::Monads[:result]

      def call(arg)
        Success(arg)
      end
    end.new
  end

  let(:step_with_arguments) do
    Class.new do # always succeeds
      include Dry::Monads[:result]

      def call(arg, user: nil) # rubocop:disable Lint/UnusedMethodArgument
        Success(arg)
      end
    end.new
  end

  before do
    tx.container.enable_stubs!
    tx.container.stub('change_set.validate', step_with_arguments)
    tx.container.stub('change_set.apply', success_step)
  end

  after do
    tx.container.unstub('change_set.validate')
    tx.container.unstub('change_set.apply')
  end

  describe '#call' do
    it 'runs the steps' do
      expect(tx.call(value).value!).to eq value
    end
  end

  describe '#with_step_args' do
    let(:user) { :FAKE_USER }

    it 'passes step options' do
      expect(tx.container['change_set.validate'])
        .to receive(:call)
        .with(value, user: user)
        .and_call_original

      tx.with_step_args('change_set.validate' => [{ user: user }]).call(value)
    end

    it 'rejects options for mismatched steps' do
      expect { tx.with_step_args('fake.step' => [:arg]) }
        .to raise_error ArgumentError
    end
  end
end
