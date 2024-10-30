# frozen_string_literal: true
RSpec.describe Hyrax::Lockable do
  let(:lock_manager) { instance_double(Hyrax::LockManager) }

  subject do
    Class.new.include(described_class).new.tap do |lockable|
      lockable.instance_variable_set(:@lock_manager, lock_manager)
    end
  end

  describe "acquire_lock_for" do
    it 'acquires the lock' do
      key = 'a key'
      block = proc {}
      expect(lock_manager).to receive(:lock).with(key, &block)
      subject.acquire_lock_for(key, &block)
    end
  end
end
