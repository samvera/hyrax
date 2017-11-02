RSpec.describe ImportUrlJob do
  let(:user) { create(:user) }

  let(:file_path) { fixture_path + '/world.png' }
  let(:file_hash) { '/673467823498723948237462429793840923582' }

  let(:file_set) do
    create_for_repository(:file_set,
                          import_url: "http://example.org#{file_hash}",
                          label: file_path,
                          title: ['File One'],
                          user: user)
  end

  let(:operation) { create(:operation) }
  let(:actor) { instance_double(Hyrax::Actors::FileSetActor, create_content: true) }

  before do
    allow(Hyrax::Actors::FileSetActor).to receive(:new).with(FileSet, user).and_return(actor)

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
      expect(actor).to receive(:create_content).with(File, from_url: true).and_return(true)
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
