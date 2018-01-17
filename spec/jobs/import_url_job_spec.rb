RSpec.describe ImportUrlJob do
  let(:user) { create(:user) }

  let(:file_path) { fixture_path + '/world.png' }
  let(:file_hash) { '/673467823498723948237462429793840923582' }

  let!(:work) do
    create_for_repository(:work, member_ids: [file_set.id])
  end

  let(:file_set) do
    create_for_repository(:file_set,
                          import_url: "http://example.org#{file_hash}",
                          label: file_path,
                          title: ['File One'],
                          user: user)
  end

  let(:operation) { create(:operation) }
  let(:wrapper) { instance_double(JobIoWrapper, ingest_file: true) }

  before do
    allow(JobIoWrapper).to receive(:create_with_varied_file_handling!).and_return(wrapper)

    response_headers = { 'Content-Type' => 'image/png', 'Content-Length' => File.size(File.expand_path(file_path, __FILE__)) }

    stub_request(:head, "http://example.org#{file_hash}").to_return(
      body: "", status: 200, headers: response_headers
    )

    stub_request(:get, "http://example.org#{file_hash}").to_return(
      body: File.open(File.expand_path(file_path, __FILE__)).read, status: 200, headers: response_headers
    )
  end

  context 'after running the job' do
    it 'creates the content and updates the associated operation' do
      expect(wrapper).to receive(:ingest_file).and_return(true)
      described_class.perform_now(file_set, operation)
      expect(operation).to be_success
    end
  end

  context "when a batch update job is running too" do
    it "does not kill all the metadata set by other processes" do
      # run the import job
      described_class.perform_now(file_set, operation)
      # import job should not override the title set another process
      file = Hyrax::Queries.find_by(id: file_set.id)
      expect(file.title).to eq(['File One'])
    end
  end
end
