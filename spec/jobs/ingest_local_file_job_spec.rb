RSpec.describe IngestLocalFileJob do
  let(:user) { create(:user) }

  let(:file_set) { FileSet.new }
  let(:wrapper) { instance_double(JobIoWrapper, ingest_file: true) }

  before do
    allow(JobIoWrapper).to receive(:create_with_varied_file_handling!).and_return(wrapper)
  end

  it 'has attached a file' do
    described_class.perform_now(file_set, File.join(fixture_path, 'world.png'), user)
    expect(wrapper).to have_received(:ingest_file)
  end
end
