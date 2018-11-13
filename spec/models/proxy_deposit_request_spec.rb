RSpec.describe ProxyDepositRequest, type: :model do
  include ActionView::Helpers::UrlHelper

  let(:sender) { create(:user) }
  let(:receiver) { create(:user) }
  let(:receiver2) { create(:user) }
  let(:work_id) { '123abc' }
  let(:stubbed_work_query_service_class) { double(new: work_query_service) }
  let(:work_query_service) { double(work: work) }
  let(:work) { double('Work') }

  subject do
    described_class.new(work_id: work_id, sending_user: sender,
                        receiving_user: receiver, sender_comment: "please take this")
  end

  # Injecting a different work_query_service_class to avoid hitting SOLR and Fedora; I need an
  # instance variable as mocks are not allowed in the around blocks
  # rubocop:disable RSpec/InstanceVariable
  before do
    @original_work_query_service_class = described_class.work_query_service_class
    described_class.work_query_service_class = stubbed_work_query_service_class
  end

  after do
    described_class.work_query_service_class = @original_work_query_service_class
  end
  # rubocop:enable RSpec/InstanceVariable

  its(:status) { is_expected.to eq described_class::PENDING }
  it { is_expected.to be_pending }
  its(:fulfillment_date) { is_expected.to be_nil }
  its(:sender_comment) { is_expected.to eq 'please take this' }

  it { is_expected.to delegate_method(:to_s).to(:work_query_service) }
  it { is_expected.to delegate_method(:work).to(:work_query_service) }
  it { is_expected.to delegate_method(:deleted_work?).to(:work_query_service) }

  context '.incoming_for' do
    it 'returns non-deleted requests for the receiving_user' do
      deleted_work_service = double(deleted_work?: true)
      found_work_service = double(deleted_work?: false)

      found = create(:proxy_deposit_request, work_id: 'abc', sending_user: sender, receiving_user: receiver)
      allow(stubbed_work_query_service_class).to receive(:new).with(id: 'abc').and_return(found_work_service)

      _deleted = create(:proxy_deposit_request, work_id: 'efg', sending_user: sender, receiving_user: receiver)
      allow(stubbed_work_query_service_class).to receive(:new).with(id: 'efg').and_return(deleted_work_service)

      _not_to_find = create(:proxy_deposit_request, work_id: 'hij', sending_user: receiver, receiving_user: sender)
      expect(described_class.incoming_for(user: receiver)).to eq([found])
    end
  end

  context '.outgoing_for' do
    it 'returns only requests for the sending_user' do
      found = create(:proxy_deposit_request, work_id: 'abc', sending_user: sender, receiving_user: receiver)
      _not_to_find = create(:proxy_deposit_request, work_id: 'hij', sending_user: receiver, receiving_user: sender)
      expect(described_class.outgoing_for(user: sender)).to eq([found])
    end
  end

  context '#status' do
    it 'is protected by enum enforcement' do
      expect { described_class.new(status: 'not_valid') }.to raise_error(ArgumentError)
    end

    # Because the Rails documentation says "Declare an enum attribute where the values map to integers in the database, but can be queried by name." but appears to not be the case.
    it 'is persisted as a string' do
      subject.cancel!
      values = described_class.connection.execute("SELECT * FROM #{described_class.quoted_table_name}")
      expect(values.first.fetch('status')).to eq(described_class::CANCELED)
    end
  end

  describe '#transfer!' do
    it 'will change the status, fulfillment_date, and perform later the ContentDepositorChangeEventJob' do
      allow(ContentDepositorChangeEventJob).to receive(:perform_later)
      subject.transfer!
      expect(subject.status).to eq(described_class::ACCEPTED)
      expect(subject.fulfillment_date).to be_a(Time)
      expect(subject).to be_accepted
    end
  end

  describe '#cancel!' do
    it 'will change the status, fulfillment_date' do
      subject.cancel!
      expect(subject.status).to eq(described_class::CANCELED)
      expect(subject.fulfillment_date).to be_a(Time)
      expect(subject).to be_canceled
    end
  end

  describe '#reject!' do
    it 'will change the status, fulfillment_date, and receiver comment' do
      subject.reject!('a comment')
      expect(subject.status).to eq(described_class::REJECTED)
      expect(subject.fulfillment_date).to be_a(Time)
      expect(subject.receiver_comment).to eq('a comment')
      expect(subject).to be_rejected
    end
  end

  describe 'transfer' do
    context 'when the transfer_to user is not found' do
      it 'raises an error' do
        subject.transfer_to = 'dave'
        expect(subject).not_to be_valid
        expect(subject.errors[:transfer_to]).to eq(['must be an existing user'])
      end
    end

    context 'when the transfer_to user is found' do
      it 'creates a transfer_request' do
        subject.transfer_to = receiver.user_key
        expect { subject.save! }.to change { receiver.mailbox.inbox(unread: true).count }.from(0).to(1)
        expect(receiver.mailbox.inbox.last.last_message.subject).to eq 'Ownership Change Request'
        user_link = link_to(sender.name, Hyrax::Engine.routes.url_helpers.user_path(sender))
        transfer_link = link_to('transfer requests', Hyrax::Engine.routes.url_helpers.transfers_path)
        expect(receiver.mailbox.inbox.last.last_message.body).to eq user_link + ' wants to transfer a work to you. Review all ' + transfer_link
        proxy_request = receiver.proxy_deposit_requests.first
        expect(proxy_request.work_id).to eq(work_id)
        expect(proxy_request.sending_user).to eq(sender)
      end

      it 'updates a transfer_request' do
        subject.transfer_to = receiver.user_key
        expect { subject.save! }.to change { receiver.mailbox.inbox(unread: true).count }.from(0).to(1)
        subject.status = described_class::ACCEPTED
        subject.save!
        expect(sender.mailbox.inbox.last.last_message.subject).to eq 'Ownership Change ' + described_class::ACCEPTED
        expect(sender.mailbox.inbox.last.last_message.body).to eq 'Your transfer request was ' + described_class::ACCEPTED + '.'
      end
    end

    context 'when the receiving user is the sending user' do
      it 'raises an error' do
        subject.transfer_to = sender.user_key
        expect(subject).not_to be_valid
        expect(subject.errors[:transfer_to]).to eq(['specify a different user to receive the work'])
      end
    end

    context 'when the work is already being transferred' do
      let(:subject2) { described_class.new(work_id: work_id, sending_user: sender, receiving_user: receiver2, sender_comment: 'please take this') }

      it 'raises an error' do
        subject.save!
        expect(subject2).not_to be_valid
        expect(subject2.errors[:open_transfer]).to eq(['must close open transfer on the work before creating a new one'])
      end

      context 'when the first transfer is closed' do
        before do
          subject.status = described_class::ACCEPTED
        end

        it 'does not raise an error' do
          expect { subject.save! }.to change { receiver.mailbox.inbox(unread: true).count }.from(0).to(1)
          expect(subject2).to be_valid
          expect(receiver.mailbox.inbox.last.last_message.subject).to eq 'Ownership Change Request'
          user_link = link_to(sender.name, Hyrax::Engine.routes.url_helpers.user_path(sender))
          transfer_link = link_to('transfer requests', Hyrax::Engine.routes.url_helpers.transfers_path)
          expect(receiver.mailbox.inbox.last.last_message.body).to eq user_link + ' wants to transfer a work to you. Review all ' + transfer_link
        end
      end
    end
  end
end
