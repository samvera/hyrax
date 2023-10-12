# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::RiiifFileResolver do
  let(:resolver) { described_class.new }

  context 'with a file' do
    let(:file_metadata) { FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file) }
    let(:file_set) { Hyrax.query_service.find_by(id: file_metadata.file_set_id) }

    describe '#find' do
      it 'returns a locally available RiiifFile using a write lock' do
        expect(resolver.file_locks[file_set.iiif_id]).to receive(:with_write_lock).and_call_original
        expect(resolver.find(file_set.iiif_id)).to be_instance_of Hyrax::RiiifFile
        expect(File.exist?(file_metadata.file.disk_path)).to eq true
      end
    end
  end

  describe '#file_locks' do
    it 'is a Concurrent::Map of Concurrent::ReadWriteLocks' do
      expect(resolver.file_locks[SecureRandom.uuid]).to be_instance_of Concurrent::ReadWriteLock
    end
  end
end
