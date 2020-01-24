# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::FileSet do
  subject(:file_set) { described_class.new }

  it_behaves_like 'a Hyrax::FileSet'

  describe '#human_readable_type' do
    it 'has a human readable type' do
      expect(file_set.human_readable_type).to eq 'File Set'
    end
  end

  describe '.original_file_use' do
    it 'returns URI for original file use' do
      expect(described_class.original_file_use).to eq ::Valkyrie::Vocab::PCDMUse.OriginalFile
    end
  end

  describe '.extracted_text_use' do
    it 'returns URI for extracted text use' do
      expect(described_class.extracted_text_use).to eq ::Valkyrie::Vocab::PCDMUse.ExtractedText
    end
  end

  describe '.thumbnail_use' do
    it 'returns URI for thumbnail use' do
      expect(described_class.thumbnail_use).to eq ::Valkyrie::Vocab::PCDMUse.Thumbnail
    end
  end
end
