# frozen_string_literal: true

RSpec.describe Hyrax::Publisher do
  subject(:publisher) { described_class.instance } # singleton instance

  describe "#default_listeners" do
    it "returns a collection of listeners" do
      # listeners can be any Object, so we can't verify they are valid here
      expect(publisher.default_listeners).to be_a Enumerable
    end

    it "returns the same collection on successive calls" do
      expect(publisher.default_listeners).to eql publisher.default_listeners
    end
  end
end
