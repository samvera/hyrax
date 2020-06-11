# frozen_string_literal: true
RSpec.describe Hyrax::LockManager do
  subject do
    described_class.new(Hyrax.config.lock_time_to_live,
                        Hyrax.config.lock_retry_count,
                        Hyrax.config.lock_retry_delay)
  end

  describe "lock", unless: ENV['TRAVIS'] do
    it "calls the block" do
      expect { |probe| subject.lock('foobar', &probe) }.to yield_with_no_args
    end
  end
end
