# frozen_string_literal: true
RSpec.describe Hyrax::Lockable do
  let(:lockable_class) { Class.new.include(described_class) }
  let(:lock_manager) { instance_double(Hyrax::LockManager) }

  subject { lockable_class.new }

  describe "lock_manager" do
    it "lazily creates a new lock manager with the default configuration" do
      expect(Hyrax::LockManager).to receive(:new).once.with(
        Hyrax.config.lock_time_to_live,
        Hyrax.config.lock_retry_count,
        Hyrax.config.lock_retry_delay
      ).and_return(lock_manager)

      expect(subject.lock_manager).to be(lock_manager)
      expect(subject.lock_manager).to be(lock_manager)
    end
  end

  describe "acquire_lock_for" do
    before do
      subject.instance_variable_set(:@lock_manager, lock_manager)
    end

    it 'acquires the lock' do
      key = 'a key'
      block = proc {}
      expect(lock_manager).to receive(:lock).with(key, &block)
      subject.acquire_lock_for(key, &block)
    end

    it 'accepts an optional ttl argument' do
      key = 'a key'
      new_ttl = 1000
      block = proc {}
      expect(lock_manager).to receive(:lock).with(key, ttl: new_ttl, &block)
      subject.acquire_lock_for(key, ttl: new_ttl, &block)
    end

    it 'accepts an optional retry_count argument' do
      key = 'a key'
      new_retry_count = 11
      block = proc {}
      expect(lock_manager).to receive(:lock).with(key, retry_count: new_retry_count, &block)
      subject.acquire_lock_for(key, retry_count: new_retry_count, &block)
    end

    it 'accepts an optional retry_delay argument' do
      key = 'a key'
      new_retry_delay = 11
      block = proc {}
      expect(lock_manager).to receive(:lock).with(key, retry_delay: new_retry_delay, &block)
      subject.acquire_lock_for(key, retry_delay: new_retry_delay, &block)
    end
  end
end
