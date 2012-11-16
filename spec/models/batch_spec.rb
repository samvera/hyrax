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

describe Batch do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    GenericFile.any_instance.expects(:characterize_if_changed).yields
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @file = GenericFile.new
    @file.apply_depositor_metadata('mjg36')
    @file.save
    @batch = Batch.create(:title => "test collection",
                          :creator => @user.user_key,
                          :part => @file.pid)
  end
  after(:all) do
    @user.delete
    @file.delete
    @batch.delete
  end
  it "should have rightsMetadata" do
    @batch.rightsMetadata.should be_instance_of Hydra::Datastream::RightsMetadata
  end
  it "should have dc desc metadata" do
    @batch.descMetadata.should be_kind_of BatchRdfDatastream
  end
  it "should belong to testuser" do
    @batch.creator.should == [@user.user_key]
  end
  it "should be titled 'test collection'" do
    @batch.title.should == ["test collection"]
  end
  it "should have generic_files defined" do
    @batch.should respond_to(:generic_files)
  end
  it "should contain one generic file" do
    @batch.part.should == [@file.pid]
  end
  it "should be able to have more than one file" do
    # not sure why this is needed here too, but when the test runs alone it is not needed but when run in the group it is needed
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    #logger.info "before create"
    gf = GenericFile.new
    #logger.info "after create"
    gf.apply_depositor_metadata('mjg36')
    gf.save
    @batch.part << gf.pid
    @batch.save
    @batch.part.should == [@file.pid, gf.pid]
    gf.delete
  end
  it "should support to_solr" do
    @batch.to_solr.should_not be_nil
    @batch.to_solr["batch__part_t"].should be_nil
    @batch.to_solr["batch__title_t"].should be_nil
    @batch.to_solr["batch__creator_t"].should be_nil
  end
  describe "find_or_create" do
    describe "when the object exists" do
      it "should find batch instead of creating" do
        Batch.expects(:create).never
        @b2 = Batch.find_or_create( @batch.pid)
      end
    end
    describe "when the object does not exist" do
      it "should create" do
        lambda {Batch.find("batch:123")}.should raise_error(ActiveFedora::ObjectNotFoundError)
        Batch.expects(:create).once.returns("the batch")
        @b2 = Batch.find_or_create( "batch:123")
        @b2.should == "the batch"
      end
    end
  end
end
