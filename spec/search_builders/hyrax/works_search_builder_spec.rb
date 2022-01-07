# frozen_string_literal: true
RSpec.describe Hyrax::WorksSearchBuilder do
  describe "::default_processor_chain" do
    it { expect(described_class.default_processor_chain).to end_with :filter_models }
  end
end
