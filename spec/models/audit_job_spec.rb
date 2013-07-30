require 'spec_helper'

describe AuditJob do
  before do
    @user = FactoryGirl.find_or_create(:user)
    @inbox = @user.mailbox.inbox
    GenericFile.any_instance.should_receive(:characterize_if_changed).and_yield
    GenericFile.any_instance.stub(:terms_of_service).and_return('1')
    @file = GenericFile.new
    @file.apply_depositor_metadata(@user)
    @file.save
    @ds = @file.datastreams.first
  end
  after do
    @file.delete
  end
  describe "passing audit" do
    it "should not send passing mail" do
      ActiveFedora::RelsExtDatastream.any_instance.stub(:dsChecksumValid).and_return(true)
      AuditJob.new(@file.pid, @ds[0], @ds[1].versionID).run
      @inbox = @user.mailbox.inbox
      @inbox.count.should == 0
    end
  end
  describe "failing audit" do
    it "should send failing mail" do
      ActiveFedora::RelsExtDatastream.any_instance.stub(:dsChecksumValid).and_return(false)
      AuditJob.new(@file.pid, @ds[0], @ds[1].versionID).run
      @inbox = @user.mailbox.inbox
      @inbox.count.should == 1
      @inbox.each { |msg| msg.last_message.subject.should == AuditJob::FAIL }
    end
  end
end
