require 'spec_helper'

describe Sufia::Arkivo::Actor do
  before do
    # Don't test characterization on these items; it breaks TravisCI and it's slow
    allow(CharacterizeJob).to receive(:perform_later)
  end

  subject { described_class.new(user, item) }

  let(:user) { create(:user) }
  let(:item) { JSON.parse(FactoryGirl.json(:post_item)) }

  describe 'Tempfile monkey-patches' do
    subject { Tempfile.new('foo') }

    it { is_expected.to respond_to(:original_filename) }
    it { is_expected.to respond_to(:original_filename=) }
    it { is_expected.to respond_to(:content_type) }
    it { is_expected.to respond_to(:content_type=) }
  end

  describe '#create_work_from_item' do
    it { is_expected.to respond_to(:create_work_from_item) }

    it 'creates a batch for loading metadata' do
      expect { subject.create_work_from_item }.to change { UploadSet.count }.by(1)
    end

    it 'instantiates an actor' do
      allow(UploadSetUpdateJob).to receive(:perform_later).once
      expect(CurationConcerns::GenericWorkActor).to receive(:new).once.and_call_original
      subject.create_work_from_item
    end

    it 'creates initial metadata' do
      expect_any_instance_of(CurationConcerns::FileSetActor).to receive(:create_metadata).once
      subject.create_work_from_item
    end

    it 'stores a checksum' do
      work = subject.create_work_from_item
      expect(work.arkivo_checksum).to eq item['file']['md5']
    end

    it 'calls create_content' do
      expect_any_instance_of(CurationConcerns::FileSetActor).to receive(:create_content).once
      subject.create_work_from_item
    end

    it 'extracts a file from the item' do
      work = subject.create_work_from_item
      expect(work.reload.file_sets.first.original_file.content).to eq "arkivo\n"
    end

    it 'batch applies metadata' do
      work = subject.create_work_from_item
      # TODO: Figure out why this is needed if the Resque job is running synchronously
      reloaded = work.reload
      expect(reloaded.title).to eq Array(item['metadata']['title'])
    end

    it 'returns a GF instance' do
      expect(subject.create_work_from_item).to be_instance_of(GenericWork)
    end
  end

  describe '#update_work_from_item' do
    let(:item) { JSON.parse(FactoryGirl.json(:put_item)) }
    let(:title) { ['ZZZZZ'] }
    let(:description) { ['This is rather lengthy.'] }
    let(:checksum) { 'abc123' }
    let(:work) do
      GenericWork.new(title: title, description: description) do |f|
        f.apply_depositor_metadata(user.user_key)
        f.arkivo_checksum = checksum
      end
    end
    let(:file_set) { create(:file_set, user: user) }

    before do
      work.ordered_members << file_set
      work.save!
    end

    it { is_expected.to respond_to(:update_work_from_item) }

    it 'instantiates an actor' do
      expect(CurationConcerns::FileSetActor).to receive(:new).once.and_call_original
      subject.update_work_from_item(work)
    end

    describe '#reset_metadata' do
      it 'changes the title' do
        # For some reason, "expect to change from to" wasn't working here
        expect(work.title).to eq title
        subject.update_work_from_item(work)
        expect(work.title).to eq Array(item['metadata']['title'])
      end

      it 'wipes out the description' do
        # For some reason, "expect to change from to" wasn't working here
        expect(work.description).to eq description
        subject.update_work_from_item(work.reload)
        expect(work.description).to eq []
      end
    end

    it 'changes the arkivo checksum' do
      expect {
        subject.update_work_from_item(work)
      }.to change { work.arkivo_checksum }.from(checksum).to(item['file']['md5'])
    end

    it 'calls update_content' do
      expect_any_instance_of(CurationConcerns::FileSetActor).to receive(:update_content).once
      subject.update_work_from_item(work)
    end

    # TODO: this is testing FileSetActor, so it is not needed here.
    it 'extracts a file from the item' do
      subject.update_work_from_item(work)
      expect(file_set.reload.original_file.content).to eq "# HEADER\n\nThis is a paragraph!\n"
    end

    it 'returns a GF instance' do
      expect(subject.update_work_from_item(work)).to be_instance_of(GenericWork)
    end
  end

  describe '#destroy_work' do
    let(:work) { create(:generic_work, user: user) }
    it 'deletes the file' do
      expect {
        subject.destroy_work(work)
      }.to change { work.destroyed? }.from(nil).to(true)
    end
  end
end
