include ActionDispatch::TestProcess

RSpec.describe ChecksumAuditLog do
  let(:file) { fixture_file_upload('world.png', 'image/png') }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:user) { create(:user) }
  let(:f) { create_for_repository(:file_set, user: user, content: file) }

  let(:version_uri) do
    # Hyrax::VersioningService.create(f.original_file)
    # TODO grab version from storage_adapter
    f.original_file.versions.first.uri
  end
  let(:content_id) { f.original_file.id }
  let(:old) { described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true, created_at: 2.minutes.ago) }
  let(:new) { described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: false, created_at: 1.minute.ago) }

  context 'a file with multiple checksums' do
    it 'returns a list of logs for this FileSet sorted by date descending' do
      logs = described_class.logs_for(f.id, checked_uri: version_uri)
      expect(logs).to eq([new, old])
    end
  end

  describe ".create_and_prune!" do
    let(:file_set_id) { 'file_set_id' }
    let(:checked_uri) { "file_id/fcr:versions/version1" }

    subject { described_class.create_and_prune!(passed: passed, file_set_id: 'file_set_id', file_id: 'file_id', checked_uri: checked_uri, expected_result: '1234') }

    describe 'when check passed' do
      let(:passed) { true }

      it { is_expected.to be_a(described_class) }
      it 'will prune history' do
        expect(described_class).to receive(:prune_history).with(file_set_id, checked_uri: checked_uri)
        subject
      end
    end
    describe 'when check failed' do
      let(:passed) { false }

      it { is_expected.to be_a(described_class) }
      it 'will not prune history' do
        expect(described_class).not_to receive(:prune_history).with(file_set_id, checked_uri: checked_uri)
        subject
      end
    end
  end

  describe ".prune_history" do
    let(:file_set_id) { "file_set_id" }
    let(:file_id) { "file_id" }
    let(:version_uri) { "#{file_id}/fcr:versions/version1" }

    context "one passing record" do
      let!(:record) { described_class.create(created_at: 1.day.ago, file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }

      before do
        described_class.prune_history(file_set_id, checked_uri: version_uri)
      end

      it "keeps record" do
        expect(described_class.logs_for(file_set_id, checked_uri: version_uri).count).to eq(1)
      end
    end

    context "two passing records" do
      let!(:older) { described_class.create(created_at: 1.day.ago, file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }
      let!(:newer) { described_class.create(created_at: 0.days.ago, file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }

      before do
        described_class.prune_history(file_set_id, checked_uri: version_uri)
      end

      it "keeps latest, gets rid of previous" do
        logs = described_class.logs_for(file_set_id, checked_uri: version_uri).to_a
        expect(logs.length).to eq 1
        expect(logs.first.id).to eq newer.id
      end
    end

    context "complex history" do
      let!(:first)  { described_class.create(file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }
      let!(:second) { described_class.create(file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }
      let!(:third)  { described_class.create(file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: false) }
      let!(:fourth) { described_class.create(file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }
      let!(:fifth)  { described_class.create(file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }
      let!(:sixth)  { described_class.create(file_set_id: file_set_id, file_id: file_id, checked_uri: version_uri, passed: true) }

      before do
        described_class.prune_history(file_set_id, checked_uri: version_uri)
      end
      it "keeps latest, failing, and previous/next of failing" do
        logs = described_class.logs_for(file_set_id, checked_uri: version_uri).reorder("created_at asc")
        expect(logs.collect(&:id)).to eq([second.id, third.id, fourth.id, sixth.id])
        expect(logs.collect(&:passed)).to eq([true, false, true, true])
      end
    end

    context 'after multiple checksum events where the checksum does not change' do
      specify 'only one of them should be kept' do
        success1 = described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true)
        described_class.prune_history(f.id, checked_uri: version_uri)
        success2 = described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true)
        described_class.prune_history(f.id, checked_uri: version_uri)
        success3 = described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true)

        described_class.prune_history(f.id, checked_uri: version_uri)

        expect { described_class.find(success1.id) }.to raise_exception ActiveRecord::RecordNotFound
        expect { described_class.find(success2.id) }.to raise_exception ActiveRecord::RecordNotFound
        expect(described_class.find(success3.id)).not_to be_nil
        logs = described_class.logs_for(f.id, checked_uri: version_uri)
        expect(logs.collect(&:id)).to eq([success3.id])
      end
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
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true, created_at: 2.days.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true, created_at: 1.day.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri, passed: true)

      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri2, passed: true, created_at: 2.days.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri2, passed: false, created_at: 1.day.ago)
      described_class.create(file_set_id: f.id, file_id: content_id, checked_uri: version_uri2, passed: true)
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
