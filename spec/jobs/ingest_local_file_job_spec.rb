require 'spec_helper'

describe IngestLocalFileJob do
  let(:user) { create(:user) }

  let(:generic_file) { GenericFile.new }
  let(:generic_file_id) { 'abc123' }
  let(:actor) { double }

  let(:mock_upload_directory) { 'spec/mock_upload_directory' }

  before do
    Dir.mkdir mock_upload_directory unless File.exist? mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), mock_upload_directory)
    allow(GenericFile).to receive(:find).with(generic_file_id).and_return(generic_file)
    allow(CurationConcerns::GenericFileActor).to receive(:new).with(generic_file, user).and_return(actor)
  end

  it 'has attached a file' do
    expect(actor).to receive(:create_content).and_return(true)
    described_class.perform_now(generic_file_id, mock_upload_directory, 'world.png', user.user_key)
  end
end
