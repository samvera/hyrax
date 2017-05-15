require 'spec_helper'

RSpec.describe Hyrax::FixityStatusService do
  let(:file_set_id) { "xw42n7888" }
  let(:file_ids) do
    [ "#{file_set_id}/files/3ec4c460-db36-49d4-914c-2d2036b0bfc6",
      "#{file_set_id}/files/c3e8d90c-e47b-4c3b-9cff-50d20b5b0583"]
  end
  let(:service) { described_class.new(file_set_id)}

  describe "#file_set_status" do
    describe "no logs recorded" do
      it "returns message" do
        expect(service.file_set_status).to eq "Fixity checks have not yet been run on this object"
      end
    end

    describe "success" do
      before do
        # Create some ChecksumAuditLots representing multiple files with multiple
        # versions on a single fileset. DANGER that this diverges from what
        # the FileSetFixityCheckService actually creats, as specs have before.
        file_ids.each do |file_id|
          ChecksumAuditLog.create!(pass: 1, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version1", created_at: 2.days.ago)
          ChecksumAuditLog.create!(pass: 1, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version2", created_at: 1.days.ago)
        end
      end
      it "creates success message with details" do
        result = service.file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"label label-success\">passed</span>")
        expect(result).to match(/2 Files with 4 total versions checked between .* and .*/)
      end
    end
    describe "failure" do
      let(:failing_file_id) { file_ids.first }
      let(:failing_checked_uri) { "#{failing_file_id}/fcr:versions/version1" }
      before do
        ChecksumAuditLog.create!(pass: 1, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version1", created_at: 2.days.ago)
        ChecksumAuditLog.create!(pass: 1, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version2", created_at: 1.days.ago)
        ChecksumAuditLog.create!(pass: 0, file_set_id: file_set_id, file_id: failing_file_id, checked_uri: failing_checked_uri, created_at: Time.now)
      end
      it "creates failure message with details" do
        result = service.file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"label label-danger\">FAIL</span>")
        expect(result).to match(/2 Files with 4 total versions checked between .* and .*/)
        expect(result).to include failing_checked_uri
        expect(result).to include failing_file_id
      end
    end
  end
end
