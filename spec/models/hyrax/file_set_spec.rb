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
    let(:original_file) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata,
      file_identifier: 'disk:///app/samvera/hyrax-webapp/storage/files/path/to/my_file.pdf',
      mime_type: "application/pdf",
      original_filename: 'my_file.pdf')
    end
    let(:thumbnail) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata,
      use: :thumbnail_file,
      file_identifier: 'disk:///app/samvera/hyrax-webapp/storage/files/path/to/thumbnail_file.jpg',
      mime_type: "image/jpeg",
      original_filename: 'thumbnail_file.jpg')
    end
    let(:files) { [original_file, thumbnail] }
    let(:file_ids) { files.map(&:id) }
    let(:results_array) do
      [{ id: thumbnail.id.to_s, extension: "jpg", mime_type: "image/jpeg", name: "thumbnail_file", use: "ThumbnailImage" },
       { id: original_file.id.to_s, extension: "pdf", mime_type: "application/pdf", name: nil, use: "OriginalFile" }]
    end

    before { file_set.file_ids = file_ids }

    it 'builds an array of extensions_and_mime_types' do
      expect(file_set.extensions_and_mime_types).to match_array results_array
    end
  end
end
