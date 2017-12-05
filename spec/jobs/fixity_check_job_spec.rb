RSpec.describe FixityCheckJob do
  include ActionDispatch::TestProcess
  let(:user) { create(:user) }
  let(:file_set) do
    create_for_repository(:file_set,
                          user: user,
                          content: file)
  end
  let(:file) { fixture_file_upload('/world.png', 'image/png') }
  let(:file_id) { file_set.original_file.id }

  describe "called with perform_now" do
    let(:log_record) { described_class.perform_now(uri, file_set_id: file_set.id, file_id: file_id) }

    describe 'fixity check the content' do
      let(:uri) { file_set.original_file.id }

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
      it "returns a ChecksumAuditLog" do
        expect(log_record).to be_kind_of ChecksumAuditLog
      end
    end

    describe 'fixity check an invalid version of the content' do
      let(:uri) { Hyrax::VersioningService.latest_version_of(file_set.original_file).uri + 'bogus' }

      it 'fails' do
        expect(log_record).to be_failed
      end
      it "returns a ChecksumAuditLog" do
        expect(log_record).to be_kind_of ChecksumAuditLog
      end
    end
  end
end
