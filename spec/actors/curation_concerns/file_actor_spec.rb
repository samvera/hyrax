require 'spec_helper'

describe CurationConcerns::Actors::FileActor do
  include ActionDispatch::TestProcess
  include CurationConcerns::FactoryHelpers

  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:relation) { create(:file_set) }
  let(:actor) { described_class.new(file_set, 'remastered', user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }

  describe '#ingest_file' do
    it 'calls ingest file job' do
      expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png$/, 'image/png', user, 'remastered')
      actor.ingest_file(uploaded_file)
    end
  end

  describe '#revert_to' do
    let(:revision_id)      { 'asdf1234' }
    let(:previous_version) { mock_file_factory }
    let(:file_path)        { 'path/to/working_file' }
    before do
      allow(file_set).to receive(:remastered).and_return(previous_version)
      allow(previous_version).to receive(:restore_version).with(revision_id)
      allow(previous_version).to receive(:original_name).and_return('original_name')
    end
    it 'reverts to a previous version of a file' do
      expect(CurationConcerns::VersioningService).to receive(:create).with(previous_version, user)
      expect(actor).to receive(:copy_repository_resource_to_working_directory).with(previous_version).and_return(file_path)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, file_path)
      actor.revert_to(revision_id)
    end
  end
end
