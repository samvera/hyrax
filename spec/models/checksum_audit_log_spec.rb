require 'spec_helper'

describe ChecksumAuditLog do
  before do
    allow_any_instance_of(GenericFile).to receive(:characterize).and_return(true) # stub out characterization so it does not get audited
  end

  let(:f) do
    GenericFile.new.tap do |gf|
      gf.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      gf.apply_depositor_metadata('mjg36')
      gf.save!
    end
  end
  let(:version) { f.datastreams['content'].versions.first }
  let(:old) do
    ChecksumAuditLog.create(pid: f.pid, dsid: version.dsid, version: version.versionID, pass: 1, created_at: 2.minutes.ago)
  end
  let(:new) do
    ChecksumAuditLog.create(pid: f.pid, dsid: version.dsid, version: version.versionID, pass: 0, created_at: 1.minute.ago)
  end

  it "should return a list of logs for this datastream sorted by date descending" do
    skip "Skipping versions for now"
    old; new
    expect(@f.logs(@version.dsid)).to eq [new, old]
  end

  it "should prune history for a datastream" do
    skip "Skipping versions for now"
    old; new
    success1 = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 1)
    ChecksumAuditLog.prune_history(@version)
    success2 = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 1)
    ChecksumAuditLog.prune_history(@version)
    success3 = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 1)
    ChecksumAuditLog.prune_history(@version)
    expect { ChecksumAuditLog.find(success2.id)}.to raise_exception ActiveRecord::RecordNotFound
    expect { ChecksumAuditLog.find(success3.id)}.to raise_exception ActiveRecord::RecordNotFound
    expect(ChecksumAuditLog.find(success1.id)).to_not be_nil
    expect(@f.logs(@version.dsid)).to eq [success1, new, old]
  end
end
