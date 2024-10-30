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

    describe 'ttl' do
      it "uses the configured ttl" do
        client = instance_double(Redlock::Client)
        allow(Redlock::Client).to receive(:new).and_return(client)

        key = 'the key'
        expect(client).to receive(:lock).with(key, ttl).and_yield(true)
        subject.lock(key) { |_| }
      end

      it "accepts an optional ttl argument" do
        new_ttl = 1000
        expect(new_ttl).not_to eq(ttl) # just to be sure

        client = instance_double(Redlock::Client)
        allow(Redlock::Client).to receive(:new).and_return(client)

        key = 'the key'
        expect(client).to receive(:lock).with(key, new_ttl).and_yield(true)
        subject.lock(key, ttl: new_ttl) { |_| }
      end
    end

    describe 'retry_count' do
      it "uses the configured retry_count" do
        client = instance_double(Redlock::Client)
        expect(Redlock::Client)
          .to receive(:new)
          .with(kind_of(Array), retry_count: retry_count, retry_delay: kind_of(Integer))
          .and_return(client)

        allow(client).to receive(:lock).and_yield(true)
        subject.lock("a key") { |_| }
      end

      it "accepts an optional retry_count argument" do
        new_retry_count = 11
        expect(new_retry_count).not_to eq(retry_count) # just to be sure

        client = instance_double(Redlock::Client)
        expect(Redlock::Client)
          .to receive(:new)
          .with(kind_of(Array), retry_count: new_retry_count, retry_delay: retry_delay)
          .and_return(client)

        allow(client).to receive(:lock).and_yield(true)
        subject.lock("a key", retry_count: new_retry_count) { |_| }
      end
    end

    describe 'retry_delay' do
      it "uses the configured retry_delay" do
        client = instance_double(Redlock::Client)
        expect(Redlock::Client)
          .to receive(:new)
          .with(kind_of(Array), retry_count: kind_of(Integer), retry_delay: retry_delay)
          .and_return(client)

        allow(client).to receive(:lock).and_yield(true)
        subject.lock("a key") { |_| }
      end

      it "accepts an optional retry_delay argument" do
        new_retry_delay = 11
        expect(new_retry_delay).not_to eq(retry_delay) # just to be sure

        client = instance_double(Redlock::Client)
        expect(Redlock::Client)
          .to receive(:new)
          .with(kind_of(Array), retry_count: retry_count, retry_delay: new_retry_delay)
          .and_return(client)

        allow(client).to receive(:lock).and_yield(true)
        subject.lock("a key", retry_delay: new_retry_delay) { |_| }
      end
    end
  end
end
