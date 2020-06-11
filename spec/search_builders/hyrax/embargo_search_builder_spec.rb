# frozen_string_literal: true
RSpec.describe Hyrax::EmbargoSearchBuilder do
  let(:context) { double }
  let(:search_builder) { described_class.new(context) }

  describe "#processor_chain" do
    subject { search_builder.processor_chain }

    it { is_expected.to eq [:with_pagination, :with_sorting, :only_active_embargoes] }
  end

  describe "#with_sorting" do
    subject { {} }

    before { search_builder.with_sorting(subject) }
    it { is_expected.to eq(sort: 'embargo_release_date_dtsi desc') }
  end
end
