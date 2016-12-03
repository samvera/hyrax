require 'spec_helper'

describe IngestLocalFileJob do
  let(:user) { create(:user) }

  let(:file_set) { FileSet.new }
  let(:actor) { double }

  let(:mock_upload_directory) { 'spec/mock_upload_directory' }

  before do
    Dir.mkdir mock_upload_directory unless File.exist? mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), mock_upload_directory)
    allow(Hyrax::Actors::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)
  end

  it 'has attached a file' do
    expect(actor).to receive(:create_content).and_return(true)
    described_class.perform_now(file_set, File.join(mock_upload_directory, 'world.png'), user)
  end
end
