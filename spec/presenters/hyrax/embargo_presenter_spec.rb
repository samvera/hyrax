# frozen_string_literal: true
RSpec.describe Hyrax::EmbargoPresenter do
  subject(:presenter) { described_class.new(document) }
  let(:document) { SolrDocument.new(attributes) }
  let(:attributes) { {} }

  describe "#visibility" do
    subject { presenter.visibility }

    it { is_expected.to eq 'restricted' }
  end

  describe "#to_s" do
    let(:attributes) { { 'title_tesim' => ['Hey guys!'] } }

    subject { presenter.to_s }

    it { is_expected.to eq 'Hey guys!' }
  end

  describe "#human_readable_type" do
    let(:attributes) { { 'human_readable_type_tesim' => ['File'] } }

    subject { presenter.human_readable_type }

    it { is_expected.to eq 'File' }
  end

  describe "embargo_release_date" do
    let(:attributes) { { 'embargo_release_date_dtsi' => '2015-10-15T00:00:00Z' } }

    subject { presenter.embargo_release_date }

    it { is_expected.to eq '15 Oct 2015' }
  end

  describe "#visibility_after_embargo" do
    let(:attributes) { { 'visibility_after_embargo_ssim' => ['restricted'] } }

    subject { presenter.visibility_after_embargo }

    it { is_expected.to eq 'restricted' }
  end

  describe "#embargo_history" do
    let(:attributes) { { 'embargo_history_ssim' => ['This is in the past'] } }

    subject { presenter.embargo_history }

    it { is_expected.to eq ['This is in the past'] }
  end

  describe "#enforced?" do
    let(:attributes) do
      { "embargo_release_date_dtsi" => "2023-08-30T00:00:00Z",
        "visibility_during_embargo_ssim" => "restricted",
        "visibility_after_embargo_ssim" => "open",
        "visibility_ssi" => "restricted" }
    end

    it { is_expected.to be_enforced }
  end
end
