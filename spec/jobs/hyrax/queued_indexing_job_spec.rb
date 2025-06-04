# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::QueuedIndexingJob do
  let(:job) { described_class.new }
  let(:redis_queue) { instance_double(Valkyrie::Indexing::RedisQueue::IndexingAdapter) }

  before do
    allow(Valkyrie::IndexingAdapter).to receive(:find).with(:redis_queue).and_return(redis_queue)
  end

  it 'includes QueuedJobBehavior' do
    expect(described_class.ancestors).to include(Hyrax::QueuedJobBehavior)
  end

  describe '#perform' do
    it 'processes items from the index queue and requeues itself' do
      expect(redis_queue).to receive(:index_queue).with(size: 200)
      expect(job).to receive(:requeue).with(size: 200)

      job.perform(size: 200)
    end

    it 'uses a default size of 200 when not specified' do
      expect(redis_queue).to receive(:index_queue).with(size: 200)
      expect(job).to receive(:requeue).with(size: 200)

      job.perform
    end

    it 'allows a custom size parameter' do
      expect(redis_queue).to receive(:index_queue).with(size: 500)
      expect(job).to receive(:requeue).with(size: 500)

      job.perform(size: 500)
    end
  end
end
