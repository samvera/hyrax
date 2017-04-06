require 'spec_helper'

RSpec.describe ChecksumAuditLog do
  let(:f) do
    file = FileSet.create do |gf|
      gf.apply_depositor_metadata('mjg36')
    end
    # TODO: Mock addition of file to fileset to avoid calls to .save.
    # This will speed up tests and avoid uneccesary integration testing for fedora funcationality.
    Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file)
    file
  end

  let(:version_uri) do
    Hyrax::VersioningService.create(f.original_file)
    f.original_file.versions.first.uri
  end
  let(:content_id) { f.original_file.id }
  let(:old) { described_class.create(file_set_id: f.id, file_id: content_id, version: version_uri, pass: 1, created_at: 2.minutes.ago) }
  let(:new) { described_class.create(file_set_id: f.id, file_id: content_id, version: version_uri, pass: 0, created_at: 1.minute.ago) }

  context 'a file with multiple checksums' do
    it 'returns a list of logs for this FileSet sorted by date descending' do
      logs = described_class.logs_for(f.id, content_id)
      expect(logs).to eq([new, old])
    end
  end

  context 'after multiple checksum events where the checksum does not change' do
    specify 'only one of them should be kept' do
      success1 = described_class.create(file_set_id: f.id, file_id: content_id, version: version_uri, pass: 1)
      described_class.prune_history(f.id, content_id)
      success2 = described_class.create(file_set_id: f.id, file_id: content_id, version: version_uri, pass: 1)
      described_class.prune_history(f.id, content_id)
      success3 = described_class.create(file_set_id: f.id, file_id: content_id, version: version_uri, pass: 1)
      described_class.prune_history(f.id, content_id)

      expect { described_class.find(success2.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect { described_class.find(success3.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect(described_class.find(success1.id)).not_to be_nil
      logs = described_class.logs_for(f.id, content_id)
      expect(logs).to eq([success1, new, old])
    end
  end

  context 'should have an fixity check log history' do
    before do
      described_class.create(file_set_id: f.id, file_id: content_id, version: 'v2', pass: 1)
      described_class.create(file_set_id: f.id, file_id: 'thumbnail', version: 'v1', pass: 1)
    end

    it "has an fixity check log history" do
      check = described_class.fixity_check_log(f.id, content_id, version_uri)
      expect(check.file_set_id).to eq(f.id)
      expect(check.version).to eq(version_uri)

      check = described_class.fixity_check_log(f.id, content_id, 'v2')
      expect(check.file_set_id).to eq(f.id)
      expect(check.version).to eq('v2')

      check = described_class.fixity_check_log(f.id, 'thumbnail', 'v1')
      expect(check.file_set_id).to eq(f.id)
      expect(check.version).to eq('v1')
    end
  end
end
