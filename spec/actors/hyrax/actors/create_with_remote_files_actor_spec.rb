# frozen_string_literal: true
RSpec.describe Hyrax::Actors::CreateWithRemoteFilesActor, :active_fedora do
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:actor) { stack.build(terminator) }
  let(:stack) do
    ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
  end
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:work) { create(:generic_work, user: user) }
  let(:url1) { "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt" }
  let(:url2) { "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf" }
  let(:file) { "file:///local/file/here.txt" }

  let(:remote_files) do
    [{ url: url1,
       expires: "2014-03-31T20:37:36.214Z",
       file_name: "filepicker-demo.txt.txt" },
     { url: url2,
       expires: "2014-03-31T20:37:36.731Z",
       file_name: "Getting+Started.pdf" }]
  end
  let(:attributes) { { remote_files: remote_files } }
  let(:environment) { Hyrax::Actors::Environment.new(work, ability, attributes) }

  before do
    allow(terminator).to receive(:create).and_return(true)
  end

  context "with source uris that are remote" do
    let(:remote_files) do
      [{ url: url1,
         expires: "2014-03-31T20:37:36.214Z",
         file_name: "filepicker-demo.txt.txt" },
       { url: url2,
         expires: "2014-03-31T20:37:36.731Z",
         file_name: "Getting+Started.pdf" }]
    end

    it "attaches files" do
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, Hyrax::Operation, {}).twice
      expect(actor.create(environment)).to be true
    end
  end

  context "with source URIs that are remote and contain encoded parameters" do
    let(:url1) { "https://dl.dropbox.com/fake/file?param1=%28example%29&param2=%5Bexample2%5D" }

    before do
      allow(::FileSet).to receive(:new).and_call_original
    end

    it "preserves the encoded parameters in the URIs" do
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, Hyrax::Operation, {}).twice
      expect(actor.create(environment)).to be true
      expect(::FileSet).to have_received(:new).with({ import_url: "https://dl.dropbox.com/fake/file?param1=%28example%29&param2=%5Bexample2%5D", label: "filepicker-demo.txt.txt" })
    end
  end

  context "with source uris that are remote bearing auth headers" do
    let(:remote_files) do
      [{ url: url1,
         expires: "2014-03-31T20:37:36.214Z",
         file_name: "filepicker-demo.txt.txt",
         auth_header: { 'Authorization' => 'Bearer access-token' } },
       { url: url2,
         expires: "2014-03-31T20:37:36.731Z",
         file_name: "Getting+Started.pdf",
         auth_header: { 'Authorization' => 'Bearer access-token' } }]
    end

    it "attaches files" do
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, Hyrax::Operation, { 'Authorization' => 'Bearer access-token' }).twice
      expect(actor.create(environment)).to be true
    end
  end

  context "with source uris that are local files" do
    let(:remote_files) do
      [{ url: file,
         expires: "2014-03-31T20:37:36.214Z",
         file_name: "here.txt" }]
    end

    before do
      allow(Hyrax.config).to receive(:registered_ingest_dirs).and_return(["/local/file/"])
    end

    it "attaches files" do
      expect(IngestLocalFileJob).to receive(:perform_later).with(FileSet, "/local/file/here.txt", user)
      expect(actor.create(environment)).to be true
    end

    context "with files from non-registered directories" do
      let(:file) { "file:///local/otherdir/test.txt" }

      it "doesn't attach files" do
        expect(IngestLocalFileJob).not_to receive(:perform_later)
        expect(actor.create(environment)).to be false
      end
    end

    context "with spaces" do
      let(:file) { "file:///local/file/ pigs .txt" }

      it "attaches files" do
        expect(IngestLocalFileJob).to receive(:perform_later).with(FileSet, "/local/file/ pigs .txt", user)
        expect(actor.create(environment)).to be true
      end
    end
  end

  describe "IngestRemoteFilesService.validate_remote_url" do
    before do
      allow(Hyrax.config).to receive(:registered_ingest_dirs).and_return(['/test/', '/local/file/'])
    end

    let(:service_class) { described_class::IngestRemoteFilesService }

    it "accepts file: urls in registered directories" do
      expect(service_class.validate_remote_url(URI('file:///local/file/test.txt'))).to be true
      expect(service_class.validate_remote_url(URI('file:///local/file/subdirectory/test.txt'))).to be true
      expect(service_class.validate_remote_url(URI('file:///test/test.txt'))).to be true
    end

    it "rejects file: urls outside registered directories" do
      expect(service_class.validate_remote_url(URI('file:///tmp/test.txt'))).to be false
      expect(service_class.validate_remote_url(URI('file:///test/../tmp/test.txt'))).to be false
      expect(service_class.validate_remote_url(URI('file:///test/'))).to be false
    end

    it "accepts other types of urls" do
      expect(service_class.validate_remote_url(URI('https://example.com/test.txt'))).to be true
    end
  end
end
