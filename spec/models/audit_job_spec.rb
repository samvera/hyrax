require 'spec_helper'

describe AuditJob do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    @inbox = @user.mailbox.inbox
    GenericFile.any_instance.expects(:characterize_if_changed).yields
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @file = GenericFile.new
    @file.apply_depositor_metadata(@user.login)
    @file.save
    @ds = @file.datastreams.first
  end
  after(:all) do
    # clear any existing messages
    @inbox.each(&:delete)
    @user.delete
    @file.delete
  end
  describe "passing audit" do
    it "should send passing mail" do
      ActiveFedora::RelsExtDatastream.any_instance.stubs(:dsChecksumValid).returns(true)
      Resque.enqueue(AuditJob, @file.pid, @ds[0], @ds[1].versionID)
      @inbox = @user.mailbox.inbox
      @inbox.count.should == 1
      @inbox.each { |msg| msg.last_message.subject.should == AuditJob::PASS }
    end
  end
  describe "failing audit" do
    it "should send failing mail" do
      ActiveFedora::RelsExtDatastream.any_instance.stubs(:dsChecksumValid).returns(false)
      Resque.enqueue(AuditJob, @file.pid, @ds[0], @ds[1].versionID)
      @inbox = @user.mailbox.inbox
      @inbox.count.should == 1
      @inbox.each { |msg| msg.last_message.subject.should == AuditJob::FAIL }
    end
  end
end
