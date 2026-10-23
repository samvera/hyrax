# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::SourceStorage do
  let(:disk) { Valkyrie::Storage::Disk.new(base_path: '/data/files') }

  after { described_class.adapter_name = nil }

  describe '.adapter' do
    it 'is the :disk adapter by default' do
      allow(Valkyrie::StorageAdapter).to receive(:find).with(:disk).and_return(disk)

      expect(described_class.adapter).to eq disk
    end

    it 'looks the adapter up under the configured name' do
      allow(Valkyrie::StorageAdapter).to receive(:find).with(:originals).and_return(disk)
      described_class.adapter_name = :originals

      expect(described_class.adapter).to eq disk
    end

    it 'refuses a versioned disk adapter' do
      allow(Valkyrie::StorageAdapter).to receive(:find).with(:disk).and_return(Valkyrie::Storage::VersionedDisk.new(base_path: '/data/files'))

      expect { described_class.adapter }.to raise_error(described_class::Unsupported, /Valkyrie::Storage::VersionedDisk.*Only Valkyrie::Storage::Disk/)
    end

    it 'names the registered adapters when there is none under the configured name' do
      allow(Valkyrie::StorageAdapter).to receive(:find).and_raise(Valkyrie::StorageAdapter::AdapterNotFoundError)
      allow(Valkyrie::StorageAdapter).to receive(:storage_adapters).and_return(versioned_disk_storage: nil, fedora_storage: nil)

      expect { described_class.adapter }.to raise_error(described_class::Unsupported, /:disk.*versioned_disk_storage, fedora_storage.*adapter_name/)
    end
  end

  context 'with a disk adapter' do
    before { allow(Valkyrie::StorageAdapter).to receive(:find).with(:disk).and_return(disk) }

    it 'recognises identifiers under the adapter base path only' do
      expect(described_class.handles?('disk:///data/files/ab/cd/file.png')).to be true
      expect(described_class.handles?('disk:///elsewhere/file.png')).to be false
      expect(described_class.handles?('versiondisk:///data/files/file.png')).to be false
      expect(described_class.handles?('shrine://bucket/key')).to be false
    end

    it 'maps an identifier to its path and exposes the base path' do
      expect(described_class.path_for('disk:///data/files/a.png')).to eq '/data/files/a.png'
      expect(described_class.base_path).to eq '/data/files'
    end
  end
end
