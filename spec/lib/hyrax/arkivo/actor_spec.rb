require 'spec_helper'

describe Hyrax::Arkivo::Actor do
  before do
    # Don't test characterization on these items; it breaks TravisCI and it's slow
    allow(CharacterizeJob).to receive(:perform_later)
    allow(Hyrax::CurationConcern).to receive(:actor).and_return(work_actor)
    allow(Hyrax::Actors::FileSetActor).to receive(:new).and_return(file_actor)
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

  let(:work_actor) { instance_double(Hyrax::Actors::ActorStack) }
  let(:file_actor) { double }

  describe '#create_work_from_item' do
    it 'creates a work and a file and returns a GenericWork' do
      expect(work_actor).to receive(:create).with(
        hash_including(arkivo_checksum: item['file']['md5'],
                       "title" => [item['metadata']['title']])
      ).and_return(true)
      expect(file_actor).to receive(:create_metadata)
      expect(file_actor).to receive(:create_content) do |tmpfile|
        expect(tmpfile).to be_instance_of Tempfile
        expect(tmpfile.read).to eq "arkivo\n"
      end
      expect(file_actor).to receive(:attach_file_to_work)

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

    it 'changes the title and clears other metadata' do
      expect(work_actor).to receive(:update).with(hash_including("title" => [item['metadata']['title']],
                                                                 "description" => [],
                                                                 arkivo_checksum: item['file']['md5']))
      expect(file_actor).to receive(:update_content) do |tmpfile|
        expect(tmpfile).to be_instance_of Tempfile
        expect(tmpfile.read).to eq "# HEADER\n\nThis is a paragraph!\n"
      end
      expect(subject.update_work_from_item(work)).to be_instance_of(GenericWork)
    end
  end

  describe '#destroy_work' do
    let(:work) { mock_model(GenericWork) }
    it 'deletes the file' do
      expect(work).to receive(:destroy)
      subject.destroy_work(work)
    end
  end
end
