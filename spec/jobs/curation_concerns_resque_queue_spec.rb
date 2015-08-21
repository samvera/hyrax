require 'spec_helper'

describe CurationConcerns::Resque::Queue do
  let(:subject) { described_class.new 'test_queue' }
  let(:job) { double('job') }

  context 'with no retries' do
    it 'queues the job' do
      expect(::Resque).to receive(:enqueue_to).once.and_return(true)
      subject.push(job)
    end
  end

  context 'when one run times out' do
    before do
      call_count = 0
      allow(::Resque).to receive(:enqueue_to) do
        call_count += 1
        call_count == 1 ? fail(Redis::TimeoutError) : true
      end
    end

    it 'retries the job' do
      expect(::Resque).to receive(:enqueue_to).twice
      subject.push(job)
    end
  end

  context 'when a job times out three times' do
    before do
      allow(::Resque).to receive(:enqueue_to).exactly(3).times.and_raise(Redis::TimeoutError)
    end

    it 'raises an error' do
      expect { subject.push(job) }.to raise_error Redis::TimeoutError
    end
  end

  context 'with no connection to Redis' do
    before do
      allow(::Resque).to receive(:enqueue_to).once.and_raise(Redis::CannotConnectError)
    end

    it 'logs an error' do
      expect(ActiveFedora::Base.logger).to receive(:error).with('Redis is down!')
      subject.push(job)
    end
  end
end
