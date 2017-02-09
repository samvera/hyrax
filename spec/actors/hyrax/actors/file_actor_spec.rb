require 'spec_helper'

describe Hyrax::Actors::FileActor do
  include ActionDispatch::TestProcess
  include Hyrax::FactoryHelpers

  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:relation) { create(:file_set) }
  let(:actor) { described_class.new(file_set, 'remastered', user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }
  let(:ingest_options) { { mime_type: 'image/png', relation: 'remastered', filename: 'world.png' } }
  let(:working_file) { Hyrax::WorkingDirectory.copy_file_to_working_directory(uploaded_file, file_set.id) }

  describe '#ingest_file' do
    context "when the file is available locally" do
      it 'calls ingest file job' do
        expect(IngestFileJob).to receive(:perform_later).with(file_set, uploaded_file.path, user, ingest_options)
        expect(Hyrax::WorkingDirectory).not_to receive(:copy_file_to_working_directory)
        actor.ingest_file(uploaded_file, true)
      end
    end

    context "when the file is not available locally" do
      before do
        allow(actor).to receive(:working_file).with(uploaded_file).and_return(working_file)
      end
      it 'calls ingest file job' do
        expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png$/, user, ingest_options)
        actor.ingest_file(uploaded_file, true)
      end
    end

    context "when performing the ingest synchronously" do
      it 'calls ingest file job' do
        expect(IngestFileJob).to receive(:perform_now).with(file_set, uploaded_file.path, user, ingest_options)
        actor.ingest_file(uploaded_file, false)
      end
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
      expect(Hyrax::VersioningService).to receive(:create).with(previous_version, user)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, previous_version.id)
      actor.revert_to(revision_id)
    end
  end
end
