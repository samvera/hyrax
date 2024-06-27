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

  describe '#extensions_and_mime_types' do
    let(:file_set) { valkyrie_create(:hyrax_file_set) }
    let(:original_file) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                                 file: FactoryBot.create(:uploaded_file, file: File.open(Hyrax::Engine.root + 'spec/fixtures/sample-file.pdf')),
                                 file_set: file_set,
                                 mime_type: "application/pdf")
    end
    let(:thumbnail) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :thumbnail, :with_file,
                                 file_set: file_set,
                                 mime_type: "image/png")
    end
    let(:files) { [original_file, thumbnail] }
    let!(:file_ids) { files.map(&:id) }
    let(:results_array) do
      [{ id: thumbnail.id.to_s, extension: "png", mime_type: "image/png", name: "world", use: "ThumbnailImage" },
       { id: original_file.id.to_s, extension: "pdf", mime_type: "application/pdf", name: nil, use: "OriginalFile" }]
    end

    it 'builds an array of extensions_and_mime_types' do
      expect(Hyrax.custom_queries).to receive(:find_files).and_return(files)
      expect(file_set.extensions_and_mime_types).to match_array results_array
    end
  end
end
