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
  let(:old) { described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1, created_at: 2.minutes.ago) }
  let(:new) { described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 0, created_at: 1.minute.ago) }

  context 'a file with multiple checksums' do
    it 'returns a list of logs for this FileSet sorted by date descending' do
      logs = described_class.logs_for(f.id, content_id)
      expect(logs).to eq([new, old])
    end
  end

  context 'after multiple checksum events where the checksum does not change' do
    specify 'only one of them should be kept' do
      success1 = described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1)
      described_class.prune_history(f.id, content_id)
      success2 = described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1)
      described_class.prune_history(f.id, content_id)
      success3 = described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1)
      described_class.prune_history(f.id, content_id)

      expect { described_class.find(success2.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect { described_class.find(success3.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect(described_class.find(success1.id)).not_to be_nil
      logs = described_class.logs_for(f.id, content_id)
      expect(logs).to eq([success1, new, old])
    end
  end

  context "multiple versions with multiple checks" do
    # I don't quite understand how our FileSet already has multiple
    # versions, but that's great since I couldn't figure out a reasonable
    # way to create them. Note you need to #all here, or you get
    # really confusing stuff.
    let(:verisons_uri) { f.original_file.versions.all.first.uri }
    let(:version_uri2) { f.original_file.versions.all.second.uri }
    before do
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1, created_at: 2.days.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1, created_at: 1.days.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, pass: 1)

      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri2, pass: 1, created_at: 2.days.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri2, pass: 0, created_at: 1.days.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri2, pass: 1)
    end
    describe ".latest_checks" do
      it "returns only latest for each checked_uri" do
        expected = [
          described_class.where(checked_uri: version_uri).order("created_at desc").first,
          described_class.where(checked_uri: version_uri2).order("created_at desc").first
        ]
        expect(described_class.latest_checks).to match_array(expected)
      end
    end
    describe ".latest_for_file_set_id" do
      before do
        # add some for another file set, doens't matter it doesn't exist
        described_class.create(file_set_id: "somethingelse", file_id: "whatever", checked_uri: "http://example.org/w")
      end
      it "returns only the lastest check for FileSet specified" do
        expected = [
          described_class.where(checked_uri: version_uri).order("created_at desc").first,
          described_class.where(checked_uri: version_uri2).order("created_at desc").first
        ]
        expect(described_class.latest_for_file_set_id(f.id)).to match_array(expected)
      end
    end
  end


end
