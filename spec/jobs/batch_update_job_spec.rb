require 'spec_helper'

describe BatchUpdateJob do

  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:batch) { Batch.create }

  let(:work1) { FactoryGirl.create(:work, user: user) }
  let(:work2) { FactoryGirl.create(:work, user: user) }

  let!(:file) do
    GenericFile.new(batch: batch, generic_work: work1) do |file|
      file.apply_depositor_metadata(user)
      file.save!
    end
  end

  let!(:file2) do
    GenericFile.new(batch: batch, generic_work: work2) do |file|
      file.apply_depositor_metadata(user)
      file.save!
    end
  end

  describe "#run" do
    let(:title) { { file.id => ['File One'], file2.id => ['File Two'] }}
    let(:metadata) do
      { read_groups_string: '', read_users_string: 'archivist1, archivist2',
        tag: [''], permissions_attributes: {"1"=>{type:"person", name: "cam@psu.edu", access:"edit"}}  }.with_indifferent_access
    end

    let(:visibility) { "open" }

    let(:job) { BatchUpdateJob.new(user.user_key, batch.id, title, metadata, visibility) }

    context "with a failing update" do
      it "should check permissions for each file before updating" do
        expect_any_instance_of(User).to receive(:can?).with(:edit, file).and_return(false)
        expect_any_instance_of(User).to receive(:can?).with(:edit, file2).and_return(false)
        job.run
        expect(user.mailbox.inbox[0].messages[0].subject).to eq("Batch upload permission denied")
        expect(user.mailbox.inbox[0].messages[0].body).to include("data-content")
        expect(user.mailbox.inbox[0].messages[0].body).to include("These files")
      end
    end

    describe "sends events" do
      let(:s1) { double('one') }
      let(:s2) { double('two') }

      before do
        allow_any_instance_of(CurationConcern::GenericWorkActor).to receive(:copy_permissions).and_return(true)
      end

      it "should log a content update event" do
        expect_any_instance_of(User).to receive(:can?).with(:edit, file).and_return(true)
        expect_any_instance_of(User).to receive(:can?).with(:edit, file2).and_return(true)
        expect(ContentUpdateEventJob).to receive(:new).with(file.id, user.user_key).and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once
        expect(ContentUpdateEventJob).to receive(:new).with(file2.id, user.user_key).and_return(s2)
        expect(Sufia.queue).to receive(:push).with(s2).once
        job.run
        expect(user.mailbox.inbox[0].messages[0].subject).to eq("Batch upload complete")
        expect(user.mailbox.inbox[0].messages[0].body).to include("data-content")
        expect(user.mailbox.inbox[0].messages[0].body).to include("These files")
      end
    end

    describe "updates metadata" do
      before do
        allow(Sufia.queue).to receive(:push)
        job.run
      end

      it "updates the titles" do
        expect(file.reload.title).to eq ['File One']
        expect(file.edit_users).to eq [user.user_key, 'cam@psu.edu']
        expect(file.visibility).to eq "open"
        expect(file2.reload.title).to eq ['File Two']
        expect(file2.edit_users).to eq [user.user_key, 'cam@psu.edu']
        expect(file2.visibility).to eq "open"
      end

      it "updates the works metadata" do
        expect(work1.reload.title).to eq ['File One']
        expect(work1.edit_users).to eq [user.user_key, 'cam@psu.edu']
        expect(work1.visibility).to eq "open"
        expect(work2.reload.title).to eq ['File Two']
        expect(work2.edit_users).to eq [user.user_key, 'cam@psu.edu']
        expect(work2.visibility).to eq "open"
      end
    end
  end
end
