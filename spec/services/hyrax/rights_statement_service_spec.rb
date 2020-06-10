# frozen_string_literal: true
RSpec.describe Hyrax::RightsStatementService do
  let(:service) { described_class.new }

  describe "#select_active_options" do
    it "returns active terms" do
      expect(service.select_active_options).to include(["In Copyright", "http://rightsstatements.org/vocab/InC/1.0/"], ["No Known Copyright", "http://rightsstatements.org/vocab/NKC/1.0/"])
    end
  end
end
