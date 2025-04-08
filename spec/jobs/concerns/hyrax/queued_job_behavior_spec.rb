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
    it 'schedules the job to run again in 5 minutes' do
      expect(including_class).to receive(:set).and_return(including_class)
      expect(including_class).to receive(:perform_later).with('arg1', 'arg2')

      instance.send(:requeue, 'arg1', 'arg2')
    end
  end
end
