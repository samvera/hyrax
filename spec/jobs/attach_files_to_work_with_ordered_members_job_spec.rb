# frozen_string_literal: true
RSpec.describe AttachFilesToWorkWithOrderedMembersJob, perform_enqueued: [AttachFilesToWorkWithOrderedMembersJob] do
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let(:uploaded_file1) { build(:uploaded_file, file: file1) }
  let(:uploaded_file2) { build(:uploaded_file, file: file2) }
  let(:generic_work) { create(:public_generic_work) }

  it "attaches files and passes ordered_members to OrderedMembersActor" do
    expect(Hyrax::Actors::OrderedMembersActor).to receive(:new).with([FileSet, FileSet], User).and_return(Hyrax::Actors::OrderedMembersActor)
    expect(Hyrax::Actors::OrderedMembersActor).to receive(:attach_ordered_members_to_work).with(generic_work)
    described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
  end
end
