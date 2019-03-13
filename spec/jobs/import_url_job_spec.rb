RSpec.describe ImportUrlJob do
  let(:user) { create(:user) }

  let(:file_path) { fixture_path + '/world.png' }
  let(:file_hash) { '/673467823498723948237462429793840923582' }
  let(:file_name) { 'world.png' }

  let(:file_set) do
    FileSet.new(import_url: "http://example.org#{file_hash}",
                label: file_name) do |f|
      f.apply_depositor_metadata(user.user_key)
    end
  end

  let(:operation) { create(:operation) }
  let(:actor) { instance_double(Hyrax::Actors::FileSetActor, create_content: true) }

  let(:mock_retriever) { double }
  let(:inbox) { user.mailbox.inbox }

  before do
    allow(Hyrax::Actors::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)

    response_headers = {
      'Content-Type' => 'image/png',
      'Content-Length' => 1,
      'Content-Range' => "0-0/#{File.size(File.expand_path(file_path, __FILE__))}"
    }

    stub_request(:get, "http://example.org#{file_hash}").with(headers: { 'Range' => 'bytes=0-0' }).to_return(
      body: File.open(File.expand_path(file_path, __FILE__)).read(1), status: 206, headers: response_headers
    )

    stub_request(:get, "http://example.org#{file_hash}").to_return(
      body: File.open(File.expand_path(file_path, __FILE__)).read, status: 200, headers: response_headers
    )

    allow(BrowseEverything::Retriever).to receive(:new).and_return(mock_retriever)
    allow(mock_retriever).to receive(:retrieve)
  end

  context 'before enqueueing the job' do
    before do
      file_set.id = 'fsid123'
    end

    describe '.operation' do
      it 'fetches the operation' do
        described_class.perform_later(file_set, operation)
        expect { subject.operation.to eq Hyrax::Operation }
      end
    end
  end

  context 'after running the job' do
    let!(:tmpdir) { Rails.root.join("tmp/spec/#{Process.pid}") }

    before do
      file_set.id = 'abc123'
      allow(file_set).to receive(:reload)

      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end

    it 'creates the content and updates the associated operation' do
      expect(actor).to receive(:create_content).with(File, from_url: true).and_return(true)
      described_class.perform_now(file_set, operation)
      expect(operation).to be_success
    end

    it 'leaves the temp directory in place' do
      described_class.perform_now(file_set, operation)
      file_name = File.basename(file_set.label)
      expect(File.exist?(File.join(tmpdir, file_name))).to be true
    end
  end

  context "when a batch update job is running too" do
    let(:title) { { file_set.id => ['File One'] } }
    let(:file_set_id) { file_set.id }

    before do
      file_set.save!
      allow(ActiveFedora::Base).to receive(:find).and_call_original
      allow(ActiveFedora::Base).to receive(:find).with(file_set_id).and_return(file_set)
      # run the batch job to set the title
      file_set.update(title: ['File One'])
    end

    it "does not kill all the metadata set by other processes" do
      # run the import job
      described_class.perform_now(file_set, operation)
      # import job should not override the title set another process
      file = FileSet.find(file_set_id)
      expect(file.title).to eq(['File One'])
    end
  end

  context 'when the remote file is unavailable' do
    before do
      stub_request(:get, "http://example.org#{file_hash}").with(headers: { 'Range' => 'bytes=0-0' }).to_return(
        body: '', status: 406, headers: {}
      )
    end

    it 'sends error message' do
      expect(operation).to receive(:fail!)
      expect(file_set.original_file).to be_nil
      described_class.perform_now(file_set, operation)
      expect(inbox.count).to eq(1)
      last_message = inbox[0].last_message
      expect(last_message.subject).to eq('File Import Error')
      expect(last_message.body).to eq("Error: Expired URL")
    end
  end

  context 'when retrieval fails' do
    before { allow(mock_retriever).to receive(:retrieve).and_raise(StandardError, 'Timeout') }

    it 'sends error message' do
      expect(operation).to receive(:fail!)
      expect(file_set.original_file).to be_nil
      described_class.perform_now(file_set, operation)
      expect(inbox.count).to eq(1)
      last_message = inbox[0].last_message
      expect(last_message.subject).to eq('File Import Error')
      expect(last_message.body).to eq("Error: Timeout")
    end
  end
end
