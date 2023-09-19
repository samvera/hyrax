# frozen_string_literal: true
RSpec.describe Hyrax::FixityCheckFailureService do
  subject(:service) { described_class.new(file_set, checksum_audit_log: checksum_audit_log) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:inbox) { depositor.mailbox.inbox }

  context "with Valkyrie models", valkyrie_adapter: :test_adapter, storage_adapter: :test_disk do
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, depositor: depositor.user_key, title: ['moomin_fs']) }
    let(:file_uri) { file_metadata.file_identifier.id }

    let(:file_metadata) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, file_set: file_set)
    end

    let(:checksum_audit_log) do
      ChecksumAuditLog.new(file_set_id: file_set.id,
                           file_id: file_metadata.id,
                           checked_uri: file_uri,
                           created_at: '2023-08-29 03:06:59',
                           updated_at: '2023-08-29 03:06:59',
                           passed: false)
    end

    describe "#call" do
      it "sends failing mail" do
        expect { service.call }.to change { inbox.count }.by 1

        inbox.each { |msg| expect(msg.last_message.subject).to eq('Failing Fixity Check') }
        inbox.each { |msg| expect(msg.last_message.body).to eq('The fixity check run at ' + checksum_audit_log.created_at.to_s + ' for moomin_fs' + ' (' + file_uri + ') failed.') }
      end
    end
  end

  context "for an ActiveFedora FileSet", :active_fedora do
    let(:file) { Hydra::PCDM::File.new }
    let(:log_date) { '2015-07-15 03:06:59' }
    let(:version_uri) { "#{file.uri}/fcr:versions/version1" }

    let(:file_set) do
      FactoryBot.create(:file_set, user: depositor, title: ["World Icon"]).tap { |fs| fs.original_file = file }
    end

    let(:checksum_audit_log) do
      ChecksumAuditLog.new(file_set_id: file_set.id,
                           file_id: file_set.original_file.id,
                           checked_uri: version_uri,
                           created_at: log_date,
                           updated_at: log_date,
                           passed: false)
    end

    describe "#call" do
      it "sends failing mail" do
        subject.call
        expect(inbox.count).to eq(1)
        inbox.each { |msg| expect(msg.last_message.subject).to eq('Failing Fixity Check') }
        inbox.each { |msg| expect(msg.last_message.body).to eq('The fixity check run at ' + checksum_audit_log.created_at.to_s + ' for ' + file_set.to_s + ' (' + version_uri + ') failed.') }
      end
    end
  end
end
