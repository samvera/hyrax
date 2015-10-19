require 'curation_concerns/callbacks/registry'

describe CurationConcerns::Callbacks::Registry do
  subject { described_class.new }

  describe "#enabled?" do
    it "returns false if the specified callback has not been enabled" do
      expect(subject.enabled?(:foo))
    end

    it "returns true after enabling the specified callback" do
      subject.enable(:foo)
      expect(subject.enabled?(:foo)).to eq true
    end
  end

  describe "#set?" do
    it "returns false if the callback has not been set" do
      expect(subject.set?(:foo)).to eq false
    end

    it "returns true if the callback has been set" do
      subject.set(:foo) { nil }
      expect(subject.set?(:foo)).to eq true
    end
  end

  describe "#set" do
    it "raises an error if a block is not given" do
      expect { subject.set(:foo) }.to raise_error CurationConcerns::Callbacks::NoBlockGiven
    end

    it "raises an error if given no arguments" do
      expect { subject.set }.to raise_error ArgumentError
    end
  end

  describe "#run" do
    it "raises a NotEnabled error if the callback has not been enabled" do
      expect { subject.run(:foo) }.to raise_error CurationConcerns::Callbacks::NotEnabled
    end

    it "runs the specified callback with parameters" do
      subject.set(:foo) { |x, y| x + y }
      expect(subject.run(:foo, 1, 2)).to eq 3
    end

    it "runs the most recently set callback" do
      subject.set(:foo) { "first" }
      subject.set(:foo) { "second" }
      expect(subject.run(:foo)).to eq "second"
    end
  end
end
