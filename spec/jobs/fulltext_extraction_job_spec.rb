require 'spec_helper'

describe FulltextExtractionJob do
  let(:file_set) { create(:file_set) }
  let(:filename) { double }

  it 'extracts the fulltext' do
    expect(Hydra::Works::FullTextExtractionService).to receive(:run).with(file_set, filename).and_return('stuff')
    described_class.perform_now file_set.id, filename
    expect(file_set.reload.extracted_text.content).to eq 'stuff'
  end
end
