# frozen_string_literal: true
RSpec.describe Hyrax::RightsStatementService do
  let(:service) { described_class.new }

  describe "#select_active_options" do
    it "returns active terms" do
      expect(service.select_active_options).to include(["In Copyright", "http://rightsstatements.org/vocab/InC/1.0/"], ["No Known Copyright", "http://rightsstatements.org/vocab/NKC/1.0/"])
    end
  end

  describe "#label" do
    it "returns the id itself when no term matches" do
      expect(service.label('not-a-known-statement')).to eq('not-a-known-statement')
    end
  end

  describe "#active?" do
    it "does not raise for an id not in the authority" do
      expect { service.active?('not-a-known-statement') }.not_to raise_error
    end

    it "returns false for an id not in the authority" do
      expect(service.active?('not-a-known-statement')).to be false
    end
  end
end
