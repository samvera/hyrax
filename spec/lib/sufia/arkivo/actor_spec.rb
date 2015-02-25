require 'spec_helper'

describe Sufia::Arkivo::Actor do
  before do
    # Don't test characterization on these items; it breaks TravisCI
    allow_any_instance_of(GenericFile).to receive(:characterize)
  end

  subject { described_class.new(user, item) }

  let(:user) { FactoryGirl.find_or_create(:archivist) }
  let(:item) { JSON.parse(FactoryGirl.json(:post_item)) }

  describe 'Tempfile monkey-patches' do
    subject { Tempfile.new('foo') }

    it { is_expected.to respond_to(:original_filename) }
    it { is_expected.to respond_to(:original_filename=) }
    it { is_expected.to respond_to(:content_type) }
    it { is_expected.to respond_to(:content_type=) }
  end

  describe '#create_file_from_item' do
    it { is_expected.to respond_to(:create_file_from_item) }

    it 'creates a batch for loading metadata' do
      expect { subject.create_file_from_item }.to change { Batch.count }.by(1)
    end

    it 'instantiates an actor' do
      expect(Sufia::GenericFile::Actor).to receive(:new).once.and_call_original
      subject.create_file_from_item
    end

    it 'creates initial metadata' do
      expect_any_instance_of(Sufia::GenericFile::Actor).to receive(:create_metadata).once
      subject.create_file_from_item
    end

    it 'stores a checksum' do
      gf = subject.create_file_from_item
      expect(gf.arkivo_checksum).to eq item['file']['md5']
    end

    it 'calls create_content' do
      expect_any_instance_of(Sufia::GenericFile::Actor).to receive(:create_content).once
      subject.create_file_from_item
    end

    it 'extracts a file from the item' do
      gf = subject.create_file_from_item
      expect(gf.content.content).to eq "arkivo\n"
    end

    it 'batch applies metadata' do
      gf = subject.create_file_from_item
      # TODO: Figure out why this is needed if the Resque job is running synchronously
      reloaded = gf.reload
      expect(reloaded.title).to eq Array(item['metadata']['title'])
    end

    it 'returns a GF instance' do
      expect(subject.create_file_from_item).to be_instance_of(GenericFile)
    end
  end

  describe '#update_file_from_item' do
    let(:item) { JSON.parse(FactoryGirl.json(:put_item)) }
    let(:title) { ['ZZZZZ'] }
    let(:description) { ['This is rather lengthy.'] }
    let(:checksum) { 'abc123' }
    let(:gf) do
      GenericFile.create(title: title, description: description) do |f|
        f.apply_depositor_metadata(user.user_key)
        f.arkivo_checksum = checksum
      end
    end

    it { is_expected.to respond_to(:update_file_from_item) }

    it 'instantiates an actor' do
      expect(Sufia::GenericFile::Actor).to receive(:new).once.and_call_original
      subject.update_file_from_item(gf)
    end

    describe '#reset_metadata' do
      it 'changes the title' do
        # For some reason, "expect to change from to" wasn't working here
        expect(gf.title).to eq title
        subject.update_file_from_item(gf)
        expect(gf.title).to eq Array(item['metadata']['title'])
      end

      it 'wipes out the description' do
        # For some reason, "expect to change from to" wasn't working here
        expect(gf.description).to eq description
        subject.update_file_from_item(gf)
        expect(gf.description).to eq []
      end
    end

    it 'changes the arkivo checksum' do
      expect {
        subject.update_file_from_item(gf)
      }.to change { gf.arkivo_checksum }.from(checksum).to(item['file']['md5'])
    end

    it 'calls update_content' do
      expect_any_instance_of(Sufia::GenericFile::Actor).to receive(:update_content).once
      subject.update_file_from_item(gf)
    end

    it 'extracts a file from the item' do
      expect {
        subject.update_file_from_item(gf)
      }.to change { gf.content.content }.to("# HEADER\n\nThis is a paragraph!\n")
    end

    it 'returns a GF instance' do
      expect(subject.update_file_from_item(gf)).to be_instance_of(GenericFile)
    end
  end

  describe '#destroy_file' do
    let(:gf) do
      GenericFile.create do |f|
        f.apply_depositor_metadata(user.user_key)
      end
    end

    it { is_expected.to respond_to(:destroy_file) }

    it 'deletes the file' do
      expect {
        subject.destroy_file(gf)
      }.to change { gf.destroyed? }.from(nil).to(true)
    end
  end
end
