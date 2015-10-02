require 'spec_helper'

describe SolrDocument do
  let(:document) { described_class.new(attributes) }

  describe "date_uploaded" do
    let(:attributes) { { 'date_uploaded_dtsi' => "2015-08-31T00:00:00Z" } }
    subject { document.date_uploaded }

    it { is_expected.to eq '08/31/2015' }
  end

  describe "visibility" do
    subject { document.visibility }

    context "when open" do
      let(:attributes) { { 'read_access_group_ssim' => ['public'] } }
      it { is_expected.to eq 'open' }
    end

    context "when authenticated" do
      let(:attributes) { { 'read_access_group_ssim' => ['registered'] } }
      it { is_expected.to eq 'authenticated' }
    end

    context "when restricted" do
      let(:attributes) { {} }
      it { is_expected.to eq 'restricted' }
    end
  end
end
