require 'spec_helper'

describe ChecksumAuditLog do
  before(:all) do
    @f = GenericFile.new
    @f.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @f.save
    @version = @f.datastreams['content'].versions.first
    @old = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>true, :created_at=>2.minutes.ago)
    @new = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>false)
    @different_ds = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>'descMetadata', :version=>'descMetadata.0', :pass=>false)
    @different_pid = ChecksumAuditLog.create(:pid=>"other_pid", :dsid=>'content', :version=>'content.0', :pass=>false)
  end
  it "should return a list of logs for this datastream sorted by date descending" do
    @f.logs(@version.dsid).should == [@new, @old]
  end
  it "should prune history for a datastream" do
    success1 = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>true)
    ChecksumAuditLog.prune_history(@version)
    success2 = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>true)
    ChecksumAuditLog.prune_history(@version)
    success3 = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>true)
    ChecksumAuditLog.prune_history(@version)
    lambda { ChecksumAuditLog.find(success2.id)}.should raise_exception ActiveRecord::RecordNotFound
    lambda { ChecksumAuditLog.find(success3.id)}.should raise_exception ActiveRecord::RecordNotFound
    ChecksumAuditLog.find(success1.id).should_not be_nil
    @f.logs(@version.dsid).should == [success1, @new, @old]
  end
  it "should not prune failed audits" do
    FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(true)
    @f.audit!
    FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(false)
    @f.audit!
    FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(false)
    @f.audit!
    FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(true)
    @f.audit!
    FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(false)
    @f.audit!
    @f.logs(@version.dsid).map(&:pass).should == [false, true, false, false, true, false, true]
  end
end
