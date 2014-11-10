require 'spec_helper'

describe ProxyDepositRequest, type: :model do
  let(:sender) { FactoryGirl.find_or_create(:jill) }
  let(:receiver) { FactoryGirl.find_or_create(:archivist) }
  let(:receiver2) { FactoryGirl.find_or_create(:curator) }
  let(:file) do
    GenericFile.new.tap do |f|
      f.title = ["Test file"]
      f.apply_depositor_metadata(sender.user_key)
      f.save!
    end
  end

  subject do
    ProxyDepositRequest.new(pid: file.id, sending_user: sender,
      receiving_user: receiver, sender_comment: "please take this")
  end

  its(:status) { is_expected.to eq 'pending' }
  it { is_expected.to be_pending }
  its(:fulfillment_date) { is_expected.to be_nil }
  its(:sender_comment) { is_expected.to eq 'please take this' }

  it "has a title for the file" do
    expect(subject.title).to eq('Test file')
  end

  context "After approval" do
    before do
      subject.transfer!
    end

    its(:status) { is_expected.to eq 'accepted' }
    its(:fulfillment_date) { is_expected.not_to be_nil }
    its(:deleted_file?) { is_expected.to be false }

    describe "and the file is deleted" do
      before do
        file.destroy
      end

      its(:title) { is_expected.to eq 'file not found' }
      its(:deleted_file?) { is_expected.to be true }
    end
  end

  context "After rejection" do
    before do
      subject.reject!('a comment')
    end

    its(:status) { is_expected.to eq 'rejected' }
    its(:fulfillment_date) { is_expected.not_to be_nil }
    its(:receiver_comment) { is_expected.to eq 'a comment' }
  end

  context "After cancel" do
    before do
      subject.cancel!
    end

    its(:status) { is_expected.to eq 'canceled' }
    its(:fulfillment_date) { is_expected.not_to be_nil }
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
        subject.save!
        proxy_request = receiver.proxy_deposit_requests.first
        expect(proxy_request.pid).to eq(file.id)
        expect(proxy_request.sending_user).to eq(sender)
      end
    end

    context 'when the receiving user is the sending user' do
      it 'raises an error' do
        subject.transfer_to = sender.user_key
        expect(subject).not_to be_valid
        expect(subject.errors[:sending_user]).to eq(['must specify another user to receive the file'])
      end
    end

    context 'when the file is already being transferred' do
      it 'raises an error' do
        subject.save!
        subject2 = ProxyDepositRequest.new(pid: file.id, sending_user: sender, receiving_user: receiver2, sender_comment: 'please take this')
        expect(subject2).not_to be_valid
        expect(subject2.errors[:open_transfer]).to eq(['must close open transfer on the file before creating a new one'])
      end
    end
  end
end
