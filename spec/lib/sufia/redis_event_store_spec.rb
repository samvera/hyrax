require 'spec_helper'

describe Sufia::RedisEventStore do
  before do
    Redis.current.keys('events:*').each { |key| Redis.current.del key }
  end

  describe "::create" do
    subject { described_class.create("some action", "1234") }
    context "when it is successful" do
      it { is_expected.to eq(1) }
    end
    context "when the Redis command fails" do
      before { allow(Redis).to receive(:current).and_raise(Redis::CommandError) }
      context "without a logger" do
        before { allow(Rails).to receive(:logger).and_return(false) }
        it { is_expected.to be_nil }
      end
      context "with a logger" do
        it "logs the error" do
          expect(Rails.logger).to receive(:error).exactly(:once).with("unable to create event: Redis::CommandError")
          expect(subject).to be_nil
        end
      end
    end
  end

  describe "#fetch" do
    subject { described_class.new("key").fetch("size") }
    context "when the Redis command fails" do
      before { allow(Redis).to receive(:current).and_raise(Redis::CommandError) }
      it { is_expected.to eq([]) }
    end
  end

  describe "#push" do
    subject { described_class.new("key").push("some value") }
    context "when the Redis command fails" do
      before { allow(Redis).to receive(:current).and_raise(Redis::CommandError) }
      it { is_expected.to be_nil }
    end
  end
end
