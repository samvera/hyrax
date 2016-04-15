require 'spec_helper'

describe CurationConcerns::FileActor do
  include ActionDispatch::TestProcess
  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:relation) { create(:file_set) }
  let(:actor) { described_class.new(file_set, 'remastered', user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }

  describe '#ingest_file' do
    it 'calls ingest file job' do
      expect(CharacterizeJob).to receive(:perform_later)
      expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png$/, 'image/png', user, 'remastered')
      actor.ingest_file(uploaded_file)
    end
  end
end
