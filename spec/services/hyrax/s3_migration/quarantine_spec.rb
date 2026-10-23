# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::Quarantine do
  let(:file_metadata) { Struct.new(:file_identifier) }
  let(:base) { Dir.mktmpdir }
  let(:content) { 'original bytes' }
  let(:relative) { '4f/54/fs1/a.png' }
  let(:disk_path) { File.join(base, relative) }
  let(:quarantined_path) { File.join(base, '.quarantine', relative) }
  let(:entry) do
    { file_set_id: 'fs1', file_metadata_id: 'fm1', old_id: "disk://#{disk_path}", new_id: 'shrine://fs1/uuid',
      size: content.bytesize, sha256: Digest::SHA256.hexdigest(content) }
  end
  let(:current) { file_metadata.new(Valkyrie::ID.new('shrine://fs1/uuid')) }
  let(:s3_content) { content }
  let(:s3_file) { double('s3_file', size: s3_content.bytesize) }
  let(:s3_storage) { double('s3_storage', find_by: s3_file) }
  let(:apply) { true }
  let(:persister) { double('persister', save: nil) }
  let(:index_adapter) { double('index_adapter', save: nil) }

  before do
    allow(Hyrax::S3Migration::SourceStorage).to receive(:adapter).and_return(Valkyrie::Storage::Disk.new(base_path: base))
    FileUtils.mkdir_p(File.dirname(disk_path))
    File.write(disk_path, content)
    allow(s3_file).to receive(:checksum) { |digests:| digests.map { |digest| digest.update(s3_content).to_s } }
    allow(Hyrax.query_service).to receive(:find_by).with(id: 'fm1').and_return(current)
    allow(Hyrax).to receive_messages(persister:, index_adapter:)
  end

  after { FileUtils.remove_entry(base) }

  def build(**options)
    described_class.new(entry, apply:, base:, s3_storage:, **options)
  end

  describe '#quarantine' do
    it 'moves the disk copy into .quarantine' do
      expect(build.quarantine).to eq :quarantined
      expect(File.exist?(disk_path)).to be false
      expect(File.read(quarantined_path)).to eq content
    end

    context 'when this is a dry run' do
      let(:apply) { false }

      it 'reports but does not move' do
        expect(build.quarantine).to eq :quarantined
        expect(File.exist?(disk_path)).to be true
        expect(File.exist?(quarantined_path)).to be false
      end
    end

    it 'reports files that are already quarantined' do
      FileUtils.mkdir_p(File.dirname(quarantined_path))
      FileUtils.mv(disk_path, quarantined_path)

      expect(build.quarantine).to eq :already_quarantined
    end

    it 'reports a missing disk copy' do
      FileUtils.rm(disk_path)

      expect(build.quarantine).to eq :disk_copy_missing
    end

    it 'leaves the file when the database no longer points at the S3 id' do
      current.file_identifier = Valkyrie::ID.new('disk://elsewhere')

      expect(build.quarantine).to eq :database_changed
      expect(File.exist?(disk_path)).to be true
    end

    context 'when the S3 object has the wrong size' do
      let(:s3_file) { double('s3_file', size: 1) }

      it 'keeps the disk copy' do
        expect(build.quarantine).to eq :s3_mismatch
        expect(File.exist?(disk_path)).to be true
      end
    end

    context 'when the S3 object has different bytes' do
      let(:s3_content) { 'tampered bytes' }

      it 'keeps the disk copy' do
        expect(build.quarantine).to eq :s3_mismatch
        expect(File.exist?(disk_path)).to be true
      end

      it 'skips the hash when asked' do
        expect(build(verify_sha: false).quarantine).to eq :quarantined
      end
    end

    context 'when the manifest path is outside the storage directory' do
      before { entry[:old_id] = 'disk:///etc/passwd' }

      it 'refuses' do
        expect(build.quarantine).to eq :outside_base
      end
    end
  end

  describe '#rollback' do
    before do
      FileUtils.mkdir_p(File.dirname(quarantined_path))
      FileUtils.mv(disk_path, quarantined_path)
    end

    it 'restores the file and the original identifier' do
      expect(build.rollback).to eq :rolled_back
      expect(File.read(disk_path)).to eq content
      expect(current.file_identifier).to eq Valkyrie::ID.new("disk://#{disk_path}")
      expect(persister).to have_received(:save).with(resource: current)
      expect(index_adapter).not_to have_received(:save)
    end

    context 'when this is a dry run' do
      let(:apply) { false }

      it 'changes nothing' do
        expect(build.rollback).to eq :rolled_back
        expect(File.exist?(disk_path)).to be false
        expect(persister).not_to have_received(:save)
      end
    end

    it 'skips files the database no longer points at' do
      current.file_identifier = Valkyrie::ID.new('disk://elsewhere')

      expect(build.rollback).to eq :skipped
    end

    it 'reports when the disk copy is gone' do
      FileUtils.rm(quarantined_path)

      expect(build.rollback).to eq :disk_copy_gone
    end
  end

  describe '.purge' do
    let(:old_file) { File.join(base, '.quarantine', 'old.bin') }
    let(:recent_file) { File.join(base, '.quarantine', 'sub', 'recent.bin') }
    let(:other_scope_file) { File.join(base, '.quarantine', 'other', 'theirs.bin') }
    let(:manifest) { instance_double(Hyrax::S3Migration::Manifest, each_entry: entries.each) }
    let(:entries) do
      [{ old_id: "disk://#{base}/old.bin" }, { old_id: "disk://#{base}/sub/recent.bin" }, { old_id: 'disk:///elsewhere/x.bin' }]
    end

    before do
      [old_file, recent_file, other_scope_file].each do |file|
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, 'x')
      end
      File.utime(30.days.ago.to_time, 30.days.ago.to_time, old_file, other_scope_file)
    end

    it 'deletes only manifested files older than the minimum age' do
      expect(described_class.purge(apply: true, min_age: 14.days, base:, manifest:)).to eq [1, 1]
      expect(File.exist?(old_file)).to be false
      expect(File.exist?(recent_file)).to be true
    end

    it 'leaves quarantined files that are not in the manifest, however old' do
      described_class.purge(apply: true, min_age: 14.days, base:, manifest:)
      expect(File.exist?(other_scope_file)).to be true
    end

    it 'removes directories it emptied and no others' do
      File.utime(30.days.ago.to_time, 30.days.ago.to_time, recent_file)
      described_class.purge(apply: true, min_age: 14.days, base:, manifest:)
      expect(Dir.exist?(File.dirname(recent_file))).to be false
      expect(Dir.exist?(File.join(base, '.quarantine'))).to be true
    end

    it 'does nothing on a dry run' do
      expect(described_class.purge(apply: false, min_age: 14.days, base:, manifest:)).to eq [1, 1]
      expect(File.exist?(old_file)).to be true
    end

    it 'handles a base path containing glob characters' do
      odd_base = File.join(base, 'a[b]*?')
      file = File.join(odd_base, '.quarantine', 'old.bin')
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, 'x')
      File.utime(30.days.ago.to_time, 30.days.ago.to_time, file)
      odd_manifest = instance_double(Hyrax::S3Migration::Manifest, each_entry: [{ old_id: "disk://#{odd_base}/old.bin" }].each)

      expect(described_class.purge(apply: true, min_age: 14.days, base: odd_base, manifest: odd_manifest)).to eq [1, 0]
      expect(File.exist?(file)).to be false
    end

    it 'refuses a minimum age that is not positive, deleting nothing' do
      [0.days, -1.day, nil].each do |min_age|
        expect { described_class.purge(apply: true, min_age:, base:, manifest:) }.to raise_error(ArgumentError, /min_age must be positive/)
      end
      expect(File.exist?(old_file)).to be true
    end
  end
end
