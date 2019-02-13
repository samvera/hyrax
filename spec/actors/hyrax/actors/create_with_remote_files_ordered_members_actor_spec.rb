RSpec.describe Hyrax::Actors::CreateWithRemoteFilesOrderedMembersActor do
  let(:null_operation) { class_double('Hyrax::Operation').as_null_object }
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
  let(:urls) { ["https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt", "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf"] }
  let(:filenames) { ['filepicker-demo.txt.txt', 'Getting%20Started.pdf'] }

  let(:remote_files) do
    urls.collect.with_index do |url, index|
      { url: url, expires: "2014-03-31T20:37:36.214Z", file_name: filenames[index] }
    end
  end

  let(:attributes) { { remote_files: remote_files } }
  let(:environment) { Hyrax::Actors::Environment.new(work, ability, attributes) }

  before do
    allow(Hyrax::Operation).to receive(:create!).and_return(null_operation)
    allow(terminator).to receive(:create).and_return(true)
  end

  context "with two file_sets" do
    it "attaches files and passes ordered_members to OrderedMembersActor in correct order" do
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, null_operation, {}).twice
      expect(actor.create(environment)).to be true
      expect(work.ordered_members.to_a.collect(&:label)).to eq(filenames)
    end
  end

  context "with two environments processed by the same actor instance simultaneously" do
    let(:work2) { create(:generic_work, user: user) }
    let(:environments) { [environment, Hyrax::Actors::Environment.new(work2, ability, attributes)] }

    # rubocop:disable RSpec/ExampleLength
    it "attaches the correct FileSets to the correct works in the correct order" do
      expect(ImportUrlJob).to receive(:perform_later).with(FileSet, null_operation, {}).exactly(4).times
      threads = environments.collect do |env|
        Thread.new do
          Rails.application.reloader.wrap do
            expect(actor.create(env)).to be true
            expect(env.curation_concern.ordered_members.to_a.collect(&:label)).to eq(filenames)
          end
        end
      end
      threads.each(&:join)
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
