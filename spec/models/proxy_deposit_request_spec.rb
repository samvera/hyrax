RSpec.describe ProxyDepositRequest, type: :model do
  let(:sender) { create(:user) }
  let(:receiver) { create(:user) }
  let(:receiver2) { create(:user) }
  let(:work_id) { '123abc' }
  let(:work) { build(:work) }

  subject do
    described_class.new(work_id: work_id, sending_user: sender,
                        receiving_user: receiver, sender_comment: "please take this")
  end

  its(:status) { is_expected.to eq described_class::PENDING }
  it { is_expected.to be_pending }
  its(:fulfillment_date) { is_expected.to be_nil }
  its(:sender_comment) { is_expected.to eq 'please take this' }

  context '.incoming_for' do
    it 'returns non-deleted requests for the receiving_user' do
      found = create(:proxy_deposit_request, work_id: 'abc', sending_user: sender, receiving_user: receiver)
      allow(Hyrax::Queries).to receive(:exists?).with(Valkyrie::ID.new('abc')).and_return(true)

      _deleted = create(:proxy_deposit_request, work_id: 'efg', sending_user: sender, receiving_user: receiver)
      allow(Hyrax::Queries).to receive(:exists?).with(Valkyrie::ID.new('efg')).and_return(false)

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
      allow(Hyrax::Queries).to receive(:find_work).with(id: Valkyrie::ID.new(work_id)).and_return(work)
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
        expect { subject.save! }.to change { receiver.mailbox.inbox(unread: true).count }
          .from(0).to(1)
        proxy_request = receiver.proxy_deposit_requests.first
        expect(proxy_request.work_id).to eq(work_id)
        expect(proxy_request.sending_user).to eq(sender)
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
          subject.save!
          expect(subject2).to be_valid
        end
      end
    end
  end

  describe '#work_exists?' do
    let(:request) { described_class.new(work_id: work_id) }

    subject { request.work_exists? }

    context 'when it does not exist' do
      before { allow(Hyrax::Queries).to receive(:exists?).with(Valkyrie::ID.new(request.work_id)).and_return(false) }
      it { is_expected.to be false }
    end
    context 'when it does exist' do
      before { allow(Hyrax::Queries).to receive(:exists?).with(Valkyrie::ID.new(request.work_id)).and_return(true) }
      it { is_expected.to be true }
    end
  end

  describe '#work' do
    let(:request) { described_class.new(work_id: work.id) }
    let(:work) { create_for_repository(:work) }

    subject { request.work.id }

    context 'when it exists' do
      it { is_expected.to eq work.id }
    end
  end

  describe '#to_s' do
    subject { request.to_s }

    context 'when the work is deleted' do
      let(:request) { described_class.new(work_id: 'non-existant') }

      it { is_expected.to eq('work not found') }
    end

    context 'when the work is not deleted' do
      let(:request) { described_class.new(work_id: work.id) }
      let(:work) { create_for_repository(:work, title: ["Test work"]) }

      it 'will retrieve the SOLR document and use the #to_s method of that' do
        expect(subject).to eq(work.title.first)
      end
    end
  end
end
