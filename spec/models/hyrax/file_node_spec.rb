# frozen_string_literal: true

require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe Hyrax::FileNode do
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:file) { fixture_file_upload('world.png', 'image/png') }
  let(:file_node) do
    described_class.for(file: file).new(id: 'test_id')
  end
  let(:uploaded_file) do
    storage_adapter.upload(file: file,
                           original_filename: file.original_filename,
                           resource: file_node)
  end

  before do
    file_node.file_identifiers = uploaded_file.id
    file_node.checksum = Hyrax::MultiChecksum.for(uploaded_file)
    file_node.size = uploaded_file.size
    persister.save(resource: file_node)
  end

  it 'sets the proper attributes' do
    expect(file_node.id.to_s).to eq 'test_id'
    expect(file_node.label).to contain_exactly('world.png')
    expect(file_node.original_filename).to contain_exactly('world.png')
    expect(file_node.mime_type).to contain_exactly('image/png')
    expect(file_node.use).to contain_exactly(Valkyrie::Vocab::PCDMUse.OriginalFile)
  end

  describe '#work?' do
    it 'is not a work' do
      expect(file_node).not_to be_work
    end
  end

  describe '#title' do
    it 'uses the label' do
      expect(file_node.title).to contain_exactly('world.png')
    end
  end

  describe '#download_id' do
    it 'uses the id' do
      expect(file_node.download_id.to_s).to eq 'test_id'
    end
  end

  describe '#original_file?' do
    it 'determines original file from use' do
      expect(file_node).to be_original_file
    end
  end

  describe "#valid?" do
    it 'is valid' do
      expect(file_node).to be_valid
    end
  end
end
