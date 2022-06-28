# frozen_string_literal: true
RSpec.describe Hyrax::FixityStatusPresenter do
  let(:file_set_id) { "xw42n7888" }
  let(:file_ids) do
    [
      "#{file_set_id}/files/3ec4c460-db36-49d4-914c-2d2036b0bfc6",
      "#{file_set_id}/files/c3e8d90c-e47b-4c3b-9cff-50d20b5b0583"
    ]
  end
  let(:presenter) { described_class.new(file_set_id) }

  describe "#render_file_set_status" do
    describe "no logs recorded" do
      it "returns message" do
        expect(presenter.render_file_set_status).to eq "Fixity checks have not yet been run on this object"
      end
    end

    describe "success" do
      before do
        # Create some ChecksumAuditLots representing multiple files with multiple
        # versions on a single fileset. BEWARE DANGER that this starts diverging from what
        # the FileSetFixityCheckService actually creates, as specs have before.
        file_ids.each do |file_id|
          ChecksumAuditLog.create!(passed: true, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version1", created_at: 2.days.ago)
          ChecksumAuditLog.create!(passed: true, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version2", created_at: 1.day.ago)
        end
      end
      it "creates success message with details" do
        result = presenter.render_file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"badge badge-success\">passed</span>")
        expect(result).to match(/2 Files with 4 total versions checked between .* and .*/)
      end
    end
    describe "failure" do
      let(:file_id) { file_ids.second }
      let(:failing_file_id) { file_ids.first }
      let(:failing_checked_uri) { "#{failing_file_id}/fcr:versions/version1" }

      before do
        ChecksumAuditLog.create!(passed: true, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version1", created_at: 2.days.ago)
        ChecksumAuditLog.create!(passed: true, file_set_id: file_set_id, file_id: file_id, checked_uri: "#{file_id}/fcr:versions/version2", created_at: 1.day.ago)
        ChecksumAuditLog.create!(passed: false, file_set_id: file_set_id, file_id: failing_file_id, checked_uri: failing_checked_uri, created_at: Time.zone.now)
      end
      it "creates failure message with details" do
        result = presenter.render_file_set_status
        expect(result).to be_html_safe
        expect(result).to include("<span class=\"badge badge-danger\">FAIL</span>")
        expect(result).to match(/2 Files with 3 total versions checked between .* and .*/)
        expect(result).to include failing_checked_uri
        expect(result).to include failing_file_id
      end
    end
  end
end
