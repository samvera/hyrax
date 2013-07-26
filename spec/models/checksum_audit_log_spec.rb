require 'spec_helper'

describe ChecksumAuditLog do
  before(:all) do
    @f = GenericFile.new
    @f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @f.apply_depositor_metadata('mjg36')
    @f.stub(:characterize_if_changed).and_yield #don't run characterization
    @f.save!
    @version = @f.datastreams['content'].versions.first
    @old = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>1, :created_at=>2.minutes.ago)
    @new = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>0)
  end
  after(:all) do
    @f.delete
    ChecksumAuditLog.all.each(&:delete)
  end
  before(:each) do
    GenericFile.any_instance.stub(:characterize).and_return(true) # stub out characterization so it does not get audited
  end
  it "should return a list of logs for this datastream sorted by date descending" do
    @f.logs(@version.dsid).should == [@new, @old]
  end
  it "should prune history for a datastream" do
    success1 = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>1)
    ChecksumAuditLog.prune_history(@version)
    success2 = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>1)
    ChecksumAuditLog.prune_history(@version)
    success3 = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>1)
    ChecksumAuditLog.prune_history(@version)
    lambda { ChecksumAuditLog.find(success2.id)}.should raise_exception ActiveRecord::RecordNotFound
    lambda { ChecksumAuditLog.find(success3.id)}.should raise_exception ActiveRecord::RecordNotFound
    ChecksumAuditLog.find(success1.id).should_not be_nil
    @f.logs(@version.dsid).should == [success1, @new, @old]
  end
end
