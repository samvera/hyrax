require 'spec_helper'

describe Sufia::Noid do
  describe "#namespaceize" do
    subject { Sufia::Noid.namespaceize(id) }

    context "when the passed in pid doesn't have a namespace" do
      let(:id) { 'abc123' }
      it { is_expected.to eq 'sufia:abc123' }
    end
    context "when the passed in pid has a namespace" do
      let(:id) { 'ksl:abc123' }
      it { is_expected.to eq 'ksl:abc123' }
    end
  end
end
