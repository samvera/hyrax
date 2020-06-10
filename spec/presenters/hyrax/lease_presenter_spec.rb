# frozen_string_literal: true
RSpec.describe Hyrax::LeasePresenter do
  let(:document) { SolrDocument.new(attributes) }
  let(:presenter) { described_class.new(document) }
  let(:attributes) { {} }

  describe "visibility" do
    subject { presenter.visibility }

    it { is_expected.to eq 'restricted' }
  end

  describe "to_s" do
    let(:attributes) { { 'title_tesim' => ['Hey guys!'] } }

    subject { presenter.to_s }

    it { is_expected.to eq 'Hey guys!' }
  end

  describe "human_readable_type" do
    let(:attributes) { { 'human_readable_type_tesim' => ['File'] } }

    subject { presenter.human_readable_type }

    it { is_expected.to eq 'File' }
  end

  describe "lease_expiration_date" do
    let(:attributes) { { 'lease_expiration_date_dtsi' => '2015-10-15T00:00:00Z' } }

    subject { presenter.lease_expiration_date }

    it { is_expected.to eq '15 Oct 2015' }
  end

  describe "visibility_after_lease" do
    let(:attributes) { { 'visibility_after_lease_ssim' => ['restricted'] } }

    subject { presenter.visibility_after_lease }

    it { is_expected.to eq 'restricted' }
  end

  describe "lease_history" do
    let(:attributes) { { 'lease_history_ssim' => ['This is in the past'] } }

    subject { presenter.lease_history }

    it { is_expected.to eq ['This is in the past'] }
  end
end
