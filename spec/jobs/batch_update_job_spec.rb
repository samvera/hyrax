require 'spec_helper'

describe BatchUpdateJob do
  
  before do
    @user = FactoryGirl.find_or_create(:jill)
    @batch = Batch.new
    @batch.save
    @file = GenericFile.new(batch: @batch)
    @file.apply_depositor_metadata(@user)
    @file.save
    @file2 = GenericFile.new(batch: @batch)
    @file2.apply_depositor_metadata('otherUser')
    @file2.save
  end
  
  after do
    @user.mailbox.inbox[0].messages[0].move_to_trash @user
    @batch.delete
    @file.delete
    @file2.delete
  end
  
  describe "#run" do
    let(:params) do
      {
        generic_file: {
          read_groups_string: '', read_users_string: 'archivist1, archivist2', tag: ['']
        }, 
        id: @batch.id,
        controller: 'batch',
        action: 'update'
      }.with_indifferent_access
    end
    context "with a failing update" do
      it "should check permissions for each file before updating" do
        expect_any_instance_of(User).to receive(:can?).with(:edit, @file).and_return(false)
        expect_any_instance_of(User).to receive(:can?).with(:edit, @file2).and_return(false)
        BatchUpdateJob.new(@user.user_key, params).run
        expect(@user.mailbox.inbox[0].messages[0].subject).to eq("Batch upload permission denied")
        expect(@user.mailbox.inbox[0].messages[0].body).to include("data-content")
        expect(@user.mailbox.inbox[0].messages[0].body).to include("These files")
      end
    end
    context "with a passing update" do
      let(:s1) { double('one') }
      let(:s2) { double('two') }
      it "should log a content update event" do
        expect_any_instance_of(User).to receive(:can?).with(:edit, @file).and_return(true)
        expect_any_instance_of(User).to receive(:can?).with(:edit, @file2).and_return(true)
        expect(ContentUpdateEventJob).to receive(:new).with(@file.id, @user.user_key).and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once
        expect(ContentUpdateEventJob).to receive(:new).with(@file2.id, @user.user_key).and_return(s2)
        expect(Sufia.queue).to receive(:push).with(s2).once
        BatchUpdateJob.new(@user.user_key, params).run
        expect(@user.mailbox.inbox[0].messages[0].subject).to eq("Batch upload complete")
        expect(@user.mailbox.inbox[0].messages[0].body).to include("data-content")
        expect(@user.mailbox.inbox[0].messages[0].body).to include("These files")
      end
    end
  end
end
