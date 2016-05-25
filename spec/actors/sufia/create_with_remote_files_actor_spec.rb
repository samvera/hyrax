describe Sufia::CreateWithRemoteFilesActor do
  let(:create_actor) { double('create actor', create: true,
                                              curation_concern: work,
                                              user: user) }
  let(:actor) do
    CurationConcerns::Actors::ActorStack.new(work, user, [described_class])
  end
  let(:user) { create(:user) }
  let(:work) { create(:generic_work, user: user) }
  let(:url1) { "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt" }
  let(:url2) { "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf" }

  let(:remote_files) { [{ url: url1,
                          expires: "2014-03-31T20:37:36.214Z",
                          file_name: "filepicker-demo.txt.txt" },
                        { url: url2,
                          expires: "2014-03-31T20:37:36.731Z",
                          file_name: "Getting+Started.pdf" }] }
  let(:attributes) { { remote_files: remote_files } }

  before do
    allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(create_actor)
    allow(create_actor).to receive(:create).and_return(true)
  end

  it "attaches files" do
    expect(ImportUrlJob).to receive(:perform_later).with(FileSet, CurationConcerns::Operation).twice
    expect(actor.create(attributes)).to be true
  end
end
