# frozen_string_literal: true
RSpec.describe Hyrax::LockManager do
  let(:ttl) { Hyrax.config.lock_time_to_live }
  let(:retry_count) { Hyrax.config.lock_retry_count }
  let(:retry_delay) { Hyrax.config.lock_retry_delay }

  subject do
    described_class.new(ttl, retry_count, retry_delay)
  end

  describe "lock", unless: ENV['TRAVIS'] do
    it "calls the block" do
      expect { |probe| subject.lock('foobar', &probe) }.to yield_with_no_args
    end

    it "uses the configured ttl" do
      client = instance_double(Redlock::Client)
      allow(Redlock::Client).to receive(:new).and_return(client)

      key = 'the key'
      expect(client).to receive(:lock).with(key, ttl).and_yield(true)
      subject.lock(key) { |_| }
    end

    it "uses the configured retry_count and retry_delay" do
      client = instance_double(Redlock::Client)
      expect(Redlock::Client)
        .to receive(:new)
        .with(kind_of(Array), retry_count: retry_count, retry_delay: retry_delay)
        .and_return(client)

      allow(client).to receive(:lock).and_yield(true)
      subject.lock("a key") { |_| }
    end
  end
end
