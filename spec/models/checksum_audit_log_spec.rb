# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe ChecksumAuditLog do
  before(:all) do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    GenericFile.any_instance.stubs(:characterize).returns(true) # stub out characterization so it does not get audited
    @f = GenericFile.new
    @f.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @f.apply_depositor_metadata('mjg36')
    @f.save
    @version = @f.datastreams['content'].versions.first
    @old = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>1, :created_at=>2.minutes.ago)
    @new = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>0)
    @different_ds = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>'descMetadata', :version=>'descMetadata.0', :pass=>0)
    @different_pid = ChecksumAuditLog.create(:pid=>"other_pid", :dsid=>'content', :version=>'content.0', :pass=>0)
  end
  after(:all) do
    @f.delete
    ChecksumAuditLog.all.each(&:delete)
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
    @f.logs(@version.dsid).map(&:pass).should == [0, 1, 0, 0, 1, 0, 1]
  end
end
