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

  describe "#subscribe_default_listeners" do
    subject(:publisher) { described_class.send(:new) }
    let(:listener) { double(on_object_deleted: nil) }

    before { allow(publisher).to receive(:default_listeners).and_return([listener]) }

    it "notifies each listener once per event when called repeatedly" do
      3.times { publisher.subscribe_default_listeners }
      publisher.publish('object.deleted', id: 'an_id', user: nil)

      expect(listener).to have_received(:on_object_deleted).once
    end
  end
end
