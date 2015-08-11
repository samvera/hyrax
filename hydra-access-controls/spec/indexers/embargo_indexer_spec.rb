require 'spec_helper'

describe Hydra::AccessControls::EmbargoIndexer do
  let(:attrs) do
    {
      visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      embargo_release_date: Date.parse('2010-10-10')
    }
  end
  let(:embargo) { Hydra::AccessControls::Embargo.new(attrs) }
  let(:indexer) { described_class.new(embargo) }
  subject { indexer.generate_solr_document }

  it "has the fields" do
    expect(subject['visibility_during_embargo_ssim']).to eq 'authenticated'
    expect(subject['visibility_after_embargo_ssim']).to eq 'open'
    expect(subject['embargo_release_date_dtsi']).to eq '2010-10-10T00:00:00Z'
  end
end
