require 'spec_helper'

describe FulltextExtractionJob do
  let(:generic_file) { create(:generic_file) }
  let(:filename) { double }

  it 'extracts the fulltext' do
    expect(Hydra::Works::FullTextExtractionService).to receive(:run).with(generic_file, filename).and_return('stuff')
    described_class.perform_now generic_file.id, filename
    expect(generic_file.reload.extracted_text.content).to eq 'stuff'
  end
end
