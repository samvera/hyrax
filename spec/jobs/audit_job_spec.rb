require 'spec_helper'

describe AuditJob do
  before do
    @user = FactoryGirl.find_or_create(:jill)
    @inbox = @user.mailbox.inbox
    @file = GenericFile.new
    @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @file.apply_depositor_metadata(@user)
    @file.save
  end

  describe "audit on content" do
    it "should pass" do
      content_uri = @file.content.uri
      job = AuditJob.new(@file.id, 'content', content_uri)
      expect(job.run).to eq(true)
    end
  end

  describe "audit on a version of the content" do
    it "should pass" do
      version_uri = @file.content.versions[0]
      job = AuditJob.new(@file.id, 'content', version_uri)
      expect(job.run).to eq(true)
    end
  end

  describe "audit on an invalid version of the content" do
    it "should fail" do
      bad_version_uri = @file.content.versions[0] + "bogus"
      job = AuditJob.new(@file.id, 'content', bad_version_uri)
      expect(job.run).to eq(false)
    end
  end

  describe "passing audit" do
    it "should not send passing mail" do
      skip "skipping audit for now"
      # allow_any_instance_of(GenericFileRdfDatastream).to receive(:dsChecksumValid).and_return(true)
      # AuditJob.new(@file.pid, "descMetadata", @file.descMetadata.versionID).run
      # audit process TBD
      @inbox = @user.mailbox.inbox
      expect(@inbox.count).to eq(0)
    end
  end
  describe "failing audit" do
    it "should send failing mail" do
      skip "skipping audit for now"
      # allow_any_instance_of(GenericFileRdfDatastream).to receive(:dsChecksumValid).and_return(false)
      # AuditJob.new(@file.pid, "descMetadata", @file.descMetadata.versionID).run
      # audit process TBD
      @inbox = @user.mailbox.inbox
      expect(@inbox.count).to eq(1)
      @inbox.each { |msg| expect(msg.last_message.subject).to eq(AuditJob::FAIL) }
    end
  end
end
