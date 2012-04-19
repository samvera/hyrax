require 'spec_helper'

describe ChecksumAuditLog do
  before(:all) do
    @f = GenericFile.new
    @f.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @f.save
    @version = @f.datastreams['content'].versions.first
  end
  it "should get an audit log for a version" do
    log = ChecksumAuditLog.get_audit_log(@version)
    #puts log.inspect
  end
  it "should prune history for a datastream" do
    log = ChecksumAuditLog.get_audit_log(@version)
    @f.audit!
    log = ChecksumAuditLog.get_audit_log(@version)
    @f.audit!
    log = ChecksumAuditLog.get_audit_log(@version)
    @f.audit!
    log = ChecksumAuditLog.get_audit_log(@version)
    @f.audit!
  end
  it "should not prune failed audits" do
    # TODO
  end
end
