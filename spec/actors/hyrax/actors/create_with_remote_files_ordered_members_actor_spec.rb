# frozen_string_literal: true
RSpec.describe Hyrax::Actors::CreateWithRemoteFilesOrderedMembersActor, :active_fedora do
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

  context "with two file_sets" do
    let(:remote_files) do
      [{ url: url1,
         expires: "2014-03-31T20:37:36.214Z",
         file_name: "filepicker-demo.txt.txt" },
       { url: url2,
         expires: "2014-03-31T20:37:36.731Z",
         file_name: "Getting+Started.pdf" }]
    end

    it "attaches files and passes ordered_members to OrderedMembersActor in correct order" do
      expect(Hyrax::Actors::OrderedMembersActor).to receive(:new).with([FileSet, FileSet], user).and_return(Hyrax::Actors::OrderedMembersActor)
      expect(Hyrax::Actors::OrderedMembersActor).to receive(:attach_ordered_members_to_work).with(work)
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, Hyrax::Operation, {}).twice
      expect(actor.create(environment)).to be true
      expect(actor.ordered_members.first.label).to eq('filepicker-demo.txt.txt')
      expect(actor.ordered_members.last.label).to eq('Getting+Started.pdf')
    end
  end
end
