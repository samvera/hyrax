require 'spec_helper'

describe ProxyDepositRequest do
  let (:sender) { FactoryGirl.find_or_create(:jill) }
  let (:receiver) { FactoryGirl.find_or_create(:archivist) }
  let (:receiver2) { FactoryGirl.find_or_create(:curator) }
  let (:file) do
    GenericFile.new.tap do |f|
      f.title = ["Test file"]
      f.apply_depositor_metadata(sender.user_key)
      f.save!
    end
  end

  after do
    subject.destroy if subject.persisted?
  end

  subject { ProxyDepositRequest.new(pid: file.pid, sending_user: sender, receiving_user: receiver, sender_comment: "please take this") }

  its(:status) {should == 'pending'}
  it {should be_pending}
  its(:fulfillment_date) {should be_nil}
  its(:sender_comment) {should == 'please take this'}

  it "should have a title for the file" do
    subject.title.should == 'Test file'
  end

  context "After approval" do
    before do
      subject.transfer!
    end
    its(:status) {should == 'accepted'}
    its(:fulfillment_date) {should_not be_nil}
    its(:deleted_file?) {should eq false}

    describe "and the file is deleted" do
      before do
        file.destroy
      end
      its(:title) {should == 'file not found'}
      its(:deleted_file?) {should eq true}
    end
  end

  context "After rejection" do
    before do
      subject.reject!('a comment')
    end
    its(:status) {should == 'rejected'}
    its(:fulfillment_date) {should_not be_nil}
    its(:receiver_comment) {should == 'a comment'}
  end

  context "After cancel" do
    before do
      subject.cancel!
    end
    its(:status) {should == 'canceled'}
    its(:fulfillment_date) {should_not be_nil}
  end

  describe "transfer" do
    context "when the transfer_to user isn't found" do
      it "should be an error" do
        subject.transfer_to = 'dave'
        subject.should_not be_valid
        subject.errors[:transfer_to].should == ["must be an existing user"]
      end
    end

    context "when the transfer_to user is found" do
      it "should create a transfer_request" do
        subject.transfer_to = receiver.user_key
        subject.save!
        proxy_request = receiver.proxy_deposit_requests.first
        proxy_request.pid.should == file.pid
        proxy_request.sending_user.should == sender
      end
    end

    context 'when the receiving user is the sending user' do
      it 'should be an error' do
        subject.transfer_to = sender.user_key
        subject.should_not be_valid
        subject.errors[:sending_user].should == ['must specify another user to receive the file']
      end
    end

    context 'when the file is already being transferred' do
      it 'should be an error' do
        subject.save!
        subject2 = ProxyDepositRequest.new(pid: file.pid, sending_user: sender, receiving_user: receiver2, sender_comment: "please take this")
        subject2.should_not be_valid
        subject2.errors[:open_transfer].should == ['must close open transfer on the file before creating a new one']
      end
    end
  end
end
