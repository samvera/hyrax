# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::FileSetLifecycleNotificationListener do
  subject(:listener) { described_class.new }
  let(:data)         { { result: :success } }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:file_set)     { create(:file_set, user: user) }
  let(:inbox)        { user.mailbox.inbox }
  let(:user)         { create(:user) }

  describe '#on_file_set_audited' do
    let(:event_type) { :on_file_set_audited }

    it 'does not raise an error; is resilient to missing event payload data' do
      expect { listener.on_file_set_audited(event) }.not_to raise_error
    end

    context 'on failure' do
      let(:data)    { { result: :failure, file_set: file_set, audit_log: log } }
      let(:file)    { Hydra::PCDM::File.new }
      let(:version) { "#{file.uri}/fcr:versions/version1" }

      let(:log) do
        ChecksumAuditLog.new(file_set_id: file_set.id,
                             file_id: file_set.original_file.id,
                             checked_uri: version,
                             created_at: '2019-11-04 03:06:59',
                             updated_at: '2019-11-04 03:06:59',
                             passed: false)
      end

      let(:file_set) do
        create(:file_set, user: user, title: ['Bad Checksum']).tap { |fs| fs.original_file = file }
      end

      it 'creates a failure message for the user' do
        expect { listener.on_file_set_audited(event) }
          .to change { inbox.last }
          .to have_attributes subject: 'Failing Fixity Check'
      end
    end
  end

  describe '#on_file_set_url_imported' do
    let(:event_type) { :on_file_set_url_imported }

    it 'does not raise an error; is resilient to missing event payload data' do
      expect { listener.on_file_set_url_imported(event) }.not_to raise_error
    end

    context 'on failure' do
      let(:data) { { result: :failure, user: user, file_set: file_set } }

      before do
        allow(file_set.errors).to receive(:full_messages).and_return(['huge mistake'])
      end

      it 'creates a failure message for the user' do
        expect { listener.on_file_set_url_imported(event) }
          .to change { inbox.last }
          .to have_attributes subject: 'File Import Error'
      end
    end
  end
end
