require 'spec_helper'

describe ChecksumAuditLog do
  before do
    # stub out characterization so it does not get audited
    allow_any_instance_of(CharacterizeJob).to receive(:run)
  end

  let(:f) do
    FileSet.create do |fs|
      fs.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      fs.apply_depositor_metadata('mjg36')
    end
  end

  let(:version_uri) do
    CurationConcerns::VersioningService.create(f.content)
    f.content.versions.first.uri
  end
  let(:version_path) { 'content' }
  let(:old) { described_class.create(file_set_id: f.id, dsid: version_path, version: version_uri, pass: 1, created_at: 2.minutes.ago) }
  let(:new) { described_class.create(file_set_id: f.id, dsid: version_path, version: version_uri, pass: 0, created_at: 1.minute.ago) }

  context "a file with multiple checksums audits" do
    specify "should return a list of logs for this datastream sorted by date descending" do
      logs = described_class.logs_for(f.id, version_path)
      expect(logs).to eq([new, old])
    end
  end

  context "after multiple checksum audits where the checksum does not change" do
    specify "only one of them should be kept" do
      success1 = described_class.create(file_set_id: f.id, dsid: version_path, version: version_uri, pass: 1)
      described_class.prune_history(f.id, version_path)
      success2 = described_class.create(file_set_id: f.id, dsid: version_path, version: version_uri, pass: 1)
      described_class.prune_history(f.id, version_path)
      success3 = described_class.create(file_set_id: f.id, dsid: version_path, version: version_uri, pass: 1)
      described_class.prune_history(f.id, version_path)

      expect { described_class.find(success2.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect { described_class.find(success3.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect(described_class.find(success1.id)).not_to be_nil
      logs = described_class.logs_for(f.id, version_path)
      expect(logs).to eq([success1, new, old])
    end
  end

  context "should have an audit log history" do
    before do
      described_class.create(file_set_id: f.id, dsid: 'content', version: 'v2', pass: 1)
      described_class.create(file_set_id: f.id, dsid: 'thumbnail', version: 'v1', pass: 1)
    end

    it "has an audit log history" do
      audit = described_class.get_audit_log(f.id, 'content', version_uri)
      expect(audit.file_set_id).to eq(f.id)
      expect(audit.version).to eq(version_uri)

      audit = described_class.get_audit_log(f.id, 'content', 'v2')
      expect(audit.file_set_id).to eq(f.id)
      expect(audit.version).to eq('v2')

      audit = described_class.get_audit_log(f.id, 'thumbnail', 'v1')
      expect(audit.file_set_id).to eq(f.id)
      expect(audit.version).to eq('v1')
    end
  end
end
