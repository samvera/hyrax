# frozen_string_literal: true

RSpec.describe Hyrax::Arkivo::Actor do
  subject { described_class.new(user, item) }

  let(:user) { create(:user) }
  let(:item) { JSON.parse(FactoryBot.json(:post_item)) }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk) }

  describe 'Tempfile monkey-patches' do
    subject { Tempfile.new('foo') }

    it { is_expected.to respond_to(:original_filename) }
    it { is_expected.to respond_to(:original_filename=) }
    it { is_expected.to respond_to(:content_type) }
    it { is_expected.to respond_to(:content_type=) }
  end

  describe '#create_work_from_item' do
    it 'creates a work and a file and returns a GenericWork' do
      saved = subject.create_work_from_item
      expect(saved).to be_instance_of(GenericWork)
      expect(saved.description).to eq ["This was funded by the NSF in 2013"]
      expect(saved.title).to eq [item['metadata']['title']]
      expect(saved.arkivo_checksum).to eq item['file']['md5']

      file_set = Hyrax::Queries.find_members(resource: saved, model: ::FileSet).first
      node = Hyrax::Queries.find_members(resource: file_set, model: Hyrax::FileNode).find { |fn| fn.use.include? Valkyrie::Vocab::PCDMUse.OriginalFile }
      binary = storage_adapter.find_by(id: node.file_identifiers.first)
      expect(binary.read).to eq "arkivo\n"
    end
  end

  describe '#update_work_from_item' do
    let(:item) { JSON.parse(FactoryBot.json(:put_item)) }
    let(:title) { ['ZZZZZ'] }
    let(:description) { ['This is rather lengthy.'] }
    let(:checksum) { 'abc123' }
    let(:work) do
      create_for_repository(:work_with_one_file,
                            user: user,
                            arkivo_checksum: checksum,
                            title: title,
                            description: description)
    end

    it 'changes the title and clears other metadata' do
      saved = subject.update_work_from_item(work)
      expect(saved).to be_instance_of(GenericWork)
      expect(saved.description).to eq []
      expect(saved.title).to eq [item['metadata']['title']]
      expect(saved.arkivo_checksum).to eq item['file']['md5']

      file_set = Hyrax::Queries.find_members(resource: work, model: ::FileSet).first
      node = Hyrax::Queries.find_members(resource: file_set, model: Hyrax::FileNode).find { |fn| fn.use.include? Valkyrie::Vocab::PCDMUse.OriginalFile }
      binary = storage_adapter.find_by(id: node.file_identifiers.first)
      expect(binary.read).to eq "# HEADER\n\nThis is a paragraph!\n"
    end
  end

  describe '#destroy_work' do
    let(:work) { create_for_repository(:work) }

    it 'deletes the file' do
      subject.destroy_work(work)
      expect { Hyrax::Queries.find_by(id: work.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
