require 'spec_helper'

describe AuditJob do
  let(:user) { FactoryGirl.create(:user) }

  let(:file) do
    GenericFile.create do |file|
      file.apply_depositor_metadata(user)
      Hydra::Works::AddFileToGenericFile.call(file, File.open(fixture_file_path('world.png')), :original_file, versioning: true)
    end
  end
  let(:file_id) { file.original_file.id }

  let(:job) { described_class.new(file.id, file_id, uri) }

  describe 'audit on content' do
    let(:uri) { file.original_file.uri }
    it 'passes' do
      expect(job.run).to eq(true)
    end
  end

  describe 'audit on a version of the content' do
    let(:uri) { CurationConcerns::VersioningService.latest_version_of(file.original_file).uri }
    it 'passes' do
      expect(job.run).to eq(true)
    end
  end

  describe 'audit on an invalid version of the content' do
    let(:uri) { CurationConcerns::VersioningService.latest_version_of(file.original_file).uri + 'bogus' }
    it 'fails' do
      expect(job.run).to eq(false)
    end
  end

  describe 'run_audit' do
    let(:uri) { CurationConcerns::VersioningService.latest_version_of(file.original_file).uri }
    let!(:old) { ChecksumAuditLog.create(generic_file_id: file.id, file_id: file_id, version: uri, pass: 1, created_at: 2.minutes.ago) }
    let!(:new) { ChecksumAuditLog.create(generic_file_id: file.id, file_id: file_id, version: uri, pass: 0) }
    let(:mock_service) { double('mock fixity check service') }

    before do
      allow(ActiveFedora::FixityService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:check).and_return(true, false, false, true, false)
    end

    it 'does not prune failed audits' do
      5.times { job.send(:run_audit) }
      expect(ChecksumAuditLog.logs_for(file.id, file_id).map(&:pass)).to eq [0, 1, 0, 0, 1, 0, 1]
    end
  end
end
