require 'spec_helper'

describe BatchUpdateJob do
  before do
    @user = FactoryGirl.find_or_create(:user)
    @batch = Batch.new
    @batch.save
    @file = GenericFile.new(:batch=>@batch)
    @file.apply_depositor_metadata(@user)
    @file.save
    @file2 = GenericFile.new(:batch=>@batch)
    @file2.apply_depositor_metadata('otherUser')
    @file2.save
  end
  after do
    @batch.delete
    @file.delete
    @file2.delete
  end
  describe "failing update" do
    it "should check permissions for each file before updating" do
      User.any_instance.should_receive(:can?).with(:edit, @file).and_return(false)
      User.any_instance.should_receive(:can?).with(:edit, @file2).and_return(false)
       params = {'generic_file' => {'read_groups_string' => '', 'read_users_string' => 'archivist1, archivist2', 'tag' => ['']}, 'id' => @batch.pid, 'controller' => 'batch', 'action' => 'update'}.with_indifferent_access
      BatchUpdateJob.new(@user.user_key, params).run
      @user.mailbox.inbox[0].messages[0].subject.should == "Batch upload permission denied"
      @user.mailbox.inbox[0].messages[0].move_to_trash @user
      #b = Batch.find(@batch.pid)
    end
  end
  describe "passing update" do
    it "should log a content update event" do
      User.any_instance.should_receive(:can?).with(:edit, @file).and_return(true)
      User.any_instance.should_receive(:can?).with(:edit, @file2).and_return(true)
      s1 = double('one')
      ContentUpdateEventJob.should_receive(:new).with(@file.pid, @user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      s2 = double('two')
      ContentUpdateEventJob.should_receive(:new).with(@file2.pid, @user.user_key).and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      params = {'generic_file' => {'read_groups_string' => '', 'read_users_string' => 'archivist1, archivist2', 'tag' => ['']}, 'id' => @batch.pid, 'controller' => 'batch', 'action' => 'update'}.with_indifferent_access
      BatchUpdateJob.new(@user.user_key, params).run
      @user.mailbox.inbox[0].messages[0].subject.should == "Batch upload complete"
      @user.mailbox.inbox[0].messages[0].move_to_trash @user
    end
  end
end
