require 'spec_helper'

describe AuditJob do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    GenericFile.any_instance.expects(:characterize_if_changed).yields
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @file = GenericFile.create
    @ds = @file.datastreams.first
    @job = AuditJob.new(@user, @file.pid, @ds[0], @ds[1].versionID)
    @inbox = @user.mailbox.inbox
  end
  after(:all) do
    @inbox.each(&:delete) # clear any existing messages
    @user.delete
    @file.delete
  end
  describe "passing audit" do
    after(:each) do
      # @inbox.each(&:delete)
    end 
    before(:all) do
      #FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(true)
      ActiveFedora::RelsExtDatastream.any_instance.stubs(:dsChecksumValid).returns(true)
      #ActiveFedora::Datastream.any_instance.stubs(:dsChecksumValid).returns(true)      
    end
    it "should send passing mail" do
      @job.perform
      @inbox = @user.mailbox.inbox
      @inbox.count.should == 1
      @inbox.each { |msg| msg.last_message.subject.should == AuditJob::PASS }
    end
  end
  describe "failing audit" do
    after(:each) do
      # @inbox.each(&:delete)
    end
    before(:all) do
      ActiveFedora::RelsExtDatastream.any_instance.stubs(:dsChecksumValid).returns(false)
      #FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(false)
    end
    it "should send failing mail" do
      @job.perform
      @inbox = @user.mailbox.inbox
      @inbox.count.should == 1
      @inbox.each { |msg| msg.last_message.subject.should == AuditJob::FAIL }
    end
  end
end
