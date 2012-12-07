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

describe BatchUpdateJob do
  before(:all) do
    GenericFile.any_instance.stub(:terms_of_service).and_return('1')
    @user = FactoryGirl.find_or_create(:user)
    @batch = Batch.new
    @batch.save
    @file = GenericFile.new(:batch=>@batch)
    @file.apply_depositor_metadata(@user.user_key)
    @file.save
    @file2 = GenericFile.new(:batch=>@batch)
    @file2.apply_depositor_metadata('otherUser')
    @file2.save
  end
  after(:all) do
    # clear any existing messages
    @batch.delete
    @user.delete
    @file.delete
    @file2.delete
  end
  describe "failing update" do
    it "should check permissions for each file before updating" do
      BatchUpdateJob.any_instance.stub(:get_permissions_solr_response_for_doc_id).and_return(["","mock solr permissions"])       
      User.any_instance.should_receive(:can?).with(:edit, "mock solr permissions").exactly(2).times
      params = {'generic_file' => {'terms_of_service' => '1', 'read_groups_string' => '', 'read_users_string' => 'archivist1, archivist2', 'tag' => ['']}, 'id' => @batch.pid, 'controller' => 'batch', 'action' => 'update'}
      BatchUpdateJob.perform(@user.user_key, params, params[:generic_file])
      @user.mailbox.inbox[0].messages[0].subject.should == "Batch upload permission denied"
      @user.mailbox.inbox[0].messages[0].move_to_trash @user
      #b = Batch.find(@batch.pid)
    end
  end
  describe "passing update" do
    it "should log a content update event" do
      BatchUpdateJob.any_instance.stub(:get_permissions_solr_response_for_doc_id).and_return(["","mock solr permissions"])       
      User.any_instance.should_receive(:can?).with(:edit, "mock solr permissions").exactly(2).times.and_return(true)
      Resque.should_receive(:enqueue).with(ContentUpdateEventJob, @file.pid, @user.user_key).once
      Resque.should_receive(:enqueue).with(ContentUpdateEventJob, @file2.pid, @user.user_key).once
      params = {'generic_file' => {'terms_of_service' => '1', 'read_groups_string' => '', 'read_users_string' => 'archivist1, archivist2', 'tag' => ['']}, 'id' => @batch.pid, 'controller' => 'batch', 'action' => 'update'}
      BatchUpdateJob.perform(@user.user_key, params, params[:generic_file])
      @user.mailbox.inbox[0].messages[0].subject.should == "Batch upload complete"
      @user.mailbox.inbox[0].messages[0].move_to_trash @user
    end
  end
end
