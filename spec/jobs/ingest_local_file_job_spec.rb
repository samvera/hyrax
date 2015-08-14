require 'spec_helper'

describe IngestLocalFileJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:generic_file) do
    GenericFile.create do |file|
      file.apply_depositor_metadata(user)
    end
  end

  let(:job) { described_class.new(generic_file.id, mock_upload_directory, 'world.png', user.user_key) }
  let(:mock_upload_directory) { 'spec/mock_upload_directory' }

  before do
    Dir.mkdir mock_upload_directory unless File.exist? mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), mock_upload_directory)
  end

  it 'has attached a file' do
    expect(CurationConcerns::CharacterizationService).to receive(:run).with(generic_file)
    job.run
    expect(generic_file.reload.original_file.size).to eq(4218)
  end
end
