# frozen_string_literal: true

return if Hyrax.config.disable_wings

RSpec.describe Hyrax::Arkivo::Actor, :active_fedora do
  before do
    # Don't test characterization on these items; it breaks TravisCI and it's slow
    allow(CharacterizeJob).to receive(:perform_later)
    allow(Hyrax::CurationConcern).to receive(:actor).and_return(work_actor)
    allow(Hyrax::Actors::FileSetActor).to receive(:new).and_return(file_actor)
  end

  subject { described_class.new(user, item) }

  let(:user) { create(:user) }
  let(:item) { JSON.parse(FactoryBot.json(:post_item)) }
  let(:work_actor) { instance_double(Hyrax::Actors::TransactionalRequest) }
  let(:file_actor) { double }

  describe 'Tempfile monkey-patches' do
    subject { Tempfile.new('foo') }

    it { is_expected.to respond_to(:original_filename) }
    it { is_expected.to respond_to(:original_filename=) }
    it { is_expected.to respond_to(:content_type) }
    it { is_expected.to respond_to(:content_type=) }
  end

  describe '#create_work_from_item' do
    it 'creates a work and a file and returns a GenericWork' do
      expect(work_actor).to receive(:create).with(Hyrax::Actors::Environment) do |env|
        expect(env.attributes).to include(arkivo_checksum: item['file']['md5'],
                                          "title" => [item['metadata']['title']])
      end.and_return(true)

      expect(file_actor).to receive(:create_metadata)
      expect(file_actor).to receive(:create_content) do |tmpfile|
        expect(tmpfile).to be_instance_of Tempfile
        expect(tmpfile.read).to eq "arkivo\n"
      end
      expect(file_actor).to receive(:attach_to_work)

      expect(subject.create_work_from_item).to be_instance_of(GenericWork)
    end
  end

  describe '#update_work_from_item' do
    let(:item) { JSON.parse(FactoryBot.json(:put_item)) }
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
      expect(work_actor).to receive(:update).with(Hyrax::Actors::Environment) do |env|
        expect(env.attributes).to include(arkivo_checksum: item['file']['md5'],
                                          "description" => [],
                                          "title" => [item['metadata']['title']])
      end.and_return(true)

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
