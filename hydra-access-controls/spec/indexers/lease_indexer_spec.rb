require 'spec_helper'

describe Hydra::AccessControls::LeaseIndexer do
  let(:attrs) do
    {
      visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      lease_expiration_date: Date.parse('2010-10-10')
    }
  end
  let(:lease) { Hydra::AccessControls::Lease.new(attrs) }
  let(:indexer) { described_class.new(lease) }
  subject { indexer.generate_solr_document }

  it "has the fields" do
    expect(subject['visibility_during_lease_ssim']).to eq 'open'
    expect(subject['visibility_after_lease_ssim']).to eq 'authenticated'
    expect(subject['lease_expiration_date_dtsi']).to eq '2010-10-10T00:00:00Z'
  end
end
