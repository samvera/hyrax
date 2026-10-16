# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::Manifest do
  subject(:manifest) { described_class.new(storage:, scope:) }

  let(:storage) { double('s3 adapter', shrine:) }
  let(:shrine) { double('shrine s3 storage', prefix: nil, upload: nil, bucket:) }
  let(:bucket) { double('bucket') }
  let(:scope) { nil }
  let(:entry) { { file_set_id: 'fs1', new_id: 'shrine://fs1/uuid', size: 3 } }

  describe '#write' do
    it 'stores one JSON object per file set through the storage adapter' do
      manifest.write(entry)

      expect(shrine).to have_received(:upload).with(an_object_having_attributes(string: entry.to_json), '_migration-manifests/fs1.json')
    end

    context 'with a scope' do
      let(:scope) { 'one.example.com' }

      it 'keeps entries under the scope' do
        manifest.write(entry)

        expect(shrine).to have_received(:upload).with(anything, '_migration-manifests/one.example.com/fs1.json')
      end
    end
  end

  describe '#read' do
    it 'returns the parsed entry' do
      allow(shrine).to receive(:open).with('_migration-manifests/fs1.json').and_return(StringIO.new(entry.to_json))

      expect(manifest.read('fs1')).to eq entry
    end

    it 'returns nil when there is no entry' do
      allow(shrine).to receive(:open).and_raise(Shrine::FileNotFound)

      expect(manifest.read('nope')).to be_nil
    end
  end

  describe '#each_entry' do
    let(:objects) do
      %w[a b].map { |id| double(id, get: double(body: StringIO.new({ file_set_id: id }.to_json))) }
    end

    it 'yields every entry under the prefix' do
      allow(bucket).to receive(:objects).with(prefix: '_migration-manifests/').and_return(objects)

      expect(manifest.each_entry.map { |e| e[:file_set_id] }).to eq %w[a b]
    end

    context 'with a scope and a storage prefix' do
      let(:scope) { 'one.example.com' }
      let(:shrine) { double('shrine s3 storage', prefix: 'repo', bucket:) }

      it 'lists only that scope, under the storage prefix' do
        allow(bucket).to receive(:objects).with(prefix: 'repo/_migration-manifests/one.example.com/').and_return(objects)

        expect(manifest.each_entry.to_a.size).to eq 2
      end
    end
  end
end
