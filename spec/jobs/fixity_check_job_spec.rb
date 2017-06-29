RSpec.describe FixityCheckJob do
  let(:user) { create(:user) }

  let(:file_set) do
    FileSet.create do |file|
      file.apply_depositor_metadata(user)
      Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file, versioning: true)
    end
  end
  let(:file_id) { file_set.original_file.id }

  describe "called with perform_now" do
    let(:log_record) { described_class.perform_now(uri, file_set_id: file_set.id, file_id: file_id) }

    describe 'fixity check the content' do
      let(:uri) { file_set.original_file.uri }

      it 'passes' do
        expect(log_record).to be_passed
      end
      it "returns a ChecksumAuditLog" do
        expect(log_record).to be_kind_of ChecksumAuditLog
        expect(log_record.checked_uri).to eq uri
        expect(log_record.file_id).to eq file_id
        expect(log_record.file_set_id).to eq file_set.id
      end
    end

    describe 'fixity check a version of the content' do
      let(:uri) { Hyrax::VersioningService.latest_version_of(file_set.original_file).uri }

      it 'passes' do
        expect(log_record).to be_passed
      end
    end

    describe 'fixity check an invalid version of the content' do
      let(:uri) { Hyrax::VersioningService.latest_version_of(file_set.original_file).uri + 'bogus' }

      it 'fails' do
        expect(log_record).to be_failed
      end
    end
  end

  describe '#run_fixity_check' do
    let(:uri) { Hyrax::VersioningService.latest_version_of(file_set.original_file).uri }
    let!(:old) { ChecksumAuditLog.create(file_set_id: file_set.id, file_id: file_id, checked_uri: uri, passed: true, created_at: 2.minutes.ago) }
    let!(:new) { ChecksumAuditLog.create(file_set_id: file_set.id, file_id: file_id, checked_uri: uri, passed: false) }
    let(:mock_service) { double('mock fixity check service') }
    let(:job) do
      described_class.new
    end

    before do
      allow(ActiveFedora::FixityService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:check).and_return(true, false, false, true, false)
    end

    it 'does not prune failed fixity checks' do
      5.times { job.send(:run_check, file_set.id, file_id, uri) }
      expect(ChecksumAuditLog.logs_for(file_set.id, checked_uri: uri).map(&:passed)).to eq [false, true, false, false, true, false, true]
    end
  end
end
