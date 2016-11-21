require 'spec_helper'

describe Sufia::LockManager do
  subject do
    described_class.new(Sufia.config.lock_time_to_live,
                        Sufia.config.lock_retry_count,
                        Sufia.config.lock_retry_delay)
  end
  describe "lock", unless: ENV['TRAVIS'] do
    it "calls the block" do
      expect { |probe| subject.lock('foobar', &probe) }.to yield_with_no_args
    end
  end
end
