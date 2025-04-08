# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::QueuedJobBehavior do
  let(:including_class) do
    Class.new(ApplicationJob) do
      include Hyrax::QueuedJobBehavior

      def perform(*_args)
        redis_queue.index_queue(size: 200)
      end
    end
  end

  let(:instance) { including_class.new }
  let(:redis_queue) { instance_double(Valkyrie::Indexing::RedisQueue::IndexingAdapter) }

  before do
    allow(Valkyrie::IndexingAdapter).to receive(:find).with(:redis_queue).and_return(redis_queue)
  end

  describe '#queue_as' do
    it 'uses the ingest queue name' do
      expect(including_class.queue_name.to_s).to eq(Hyrax.config.ingest_queue_name.to_s)
    end
  end

  describe '#redis_queue' do
    it 'finds the redis queue indexing adapter' do
      expect(Valkyrie::IndexingAdapter).to receive(:find).with(:redis_queue)
      instance.send(:redis_queue)
    end
  end

  describe '#requeue' do
    before do
      allow(including_class).to receive(:set).and_return(including_class)
      allow(including_class).to receive(:perform_later)
    end

    it 'schedules the job to run again in 5 minutes' do
      expect(including_class).to receive(:set).with(wait_until: kind_of(ActiveSupport::TimeWithZone))
      expect(including_class).to receive(:perform_later).with('arg1', 'arg2')

      instance.send(:requeue, 'arg1', 'arg2')
    end

    it 'uses the class requeue_frequency if set' do
      including_class.requeue_frequency = 10.minutes

      expect(including_class).to receive(:set) do |options|
        expect(options[:wait_until]).to be_within(1.second).of(10.minutes.from_now)
        including_class
      end

      instance.send(:requeue)
    end

    it 'defaults to 5 minutes if requeue_frequency is not set' do
      including_class.requeue_frequency = nil

      expect(including_class).to receive(:set) do |options|
        expect(options[:wait_until]).to be_within(1.second).of(5.minutes.from_now)
        including_class
      end

      instance.send(:requeue)
    end
  end
end
