RSpec.describe Hyrax::Arkivo::Actor do
  before do
    # Don't test characterization on these items; it breaks TravisCI and it's slow
    allow(CharacterizeJob).to receive(:perform_later)
    allow(Hyrax::Actors::FileSetActor).to receive(:new).and_return(file_actor)
  end

  subject { described_class.new(user, item) }

  let(:user) { create(:user) }
  let(:item) { JSON.parse(FactoryGirl.json(:post_item)) }
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
      expect(file_actor).to receive(:create_metadata)
      expect(file_actor).to receive(:create_content) do |tmpfile|
        expect(tmpfile).to be_instance_of Tempfile
        expect(tmpfile.read).to eq "arkivo\n"
      end
      work = subject.create_work_from_item
      expect(work).to be_instance_of(GenericWork)
      expect(work.title).to eq [item['metadata']['title']]
      expect(work.arkivo_checksum).to eq item['file']['md5']
    end
  end

  describe '#update_work_from_item' do
    let(:item) { JSON.parse(FactoryGirl.json(:put_item)) }
    let(:title) { ['ZZZZZ'] }
    let(:description) { ['This is rather lengthy.'] }
    let(:checksum) { 'abc123' }
    let(:work) do
      create_for_repository(:work,
                            title: title,
                            description: description,
                            user: user,
                            arkivo_checksum: checksum)
    end

    it 'changes the title and clears other metadata' do
      expect(file_actor).to receive(:update_content) do |tmpfile|
        expect(tmpfile).to be_instance_of Tempfile
        expect(tmpfile.read).to eq "# HEADER\n\nThis is a paragraph!\n"
      end
      updated = subject.update_work_from_item(work)
      expect(updated).to be_instance_of(GenericWork)
      expect(updated.title).to eq [item['metadata']['title']]
      expect(updated.description).to eq []
      expect(updated.arkivo_checksum).to eq item['file']['md5']
    end
  end

  describe '#destroy_work' do
    let(:work) { build(:work) }

    it 'deletes the file' do
      expect(work).to receive(:destroy)
      subject.destroy_work(work)
    end
  end
end
