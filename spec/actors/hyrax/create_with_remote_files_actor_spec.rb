describe Hyrax::CreateWithRemoteFilesActor do
  let(:create_actor) do
    double('create actor', create: true,
                           curation_concern: work,
                           user: user)
  end
  let(:actor) do
    Hyrax::Actors::ActorStack.new(work, ::Ability.new(user), [described_class])
  end
  let(:user) { create(:user) }
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

  before do
    allow(Hyrax::Actors::RootActor).to receive(:new).and_return(create_actor)
    allow(create_actor).to receive(:create).and_return(true)
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
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, Hyrax::Operation).twice
      expect(actor.create(attributes)).to be true
    end
  end

  context "with source uris that are local files" do
    let(:remote_files) do
      [{ url: file,
         expires: "2014-03-31T20:37:36.214Z",
         file_name: "here.txt" }]
    end

    it "attaches files" do
      expect(IngestLocalFileJob).to receive(:perform_later).with(FileSet, "/local/file/here.txt", user)
      expect(actor.create(attributes)).to be true
    end

    context "with spaces" do
      let(:file) { "file:///local/file/ pigs .txt" }
      it "attaches files" do
        expect(IngestLocalFileJob).to receive(:perform_later).with(FileSet, "/local/file/ pigs .txt", user)
        expect(actor.create(attributes)).to be true
      end
    end
  end
end
