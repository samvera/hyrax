# frozen_string_literal: true

# NOTE: This job initiates the Actor Stack with ActiveFedora objects.
RSpec.describe AttachFilesToWorkWithOrderedMembersJob, :active_fedora, perform_enqueued: [AttachFilesToWorkWithOrderedMembersJob] do
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

  context "with visibility different from parent work" do
    let(:attributes) { { file_set: [{ uploaded_file_id: uploaded_file2.id, visibility: 'restricted' }] } }

    before do
      # Ensure uploaded files have ids
      uploaded_file1.save
      uploaded_file2.save
    end

    it "overrides the work's visibility", perform_enqueued: [described_class, IngestJob] do
      expect(CharacterizeJob).to receive(:perform_later).twice
      described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2], **attributes)
      generic_work.reload
      expect(generic_work.file_sets.count).to eq 2
      expect(generic_work.file_sets.find { |fs| fs.label == uploaded_file1.file.filename }.visibility).to eq 'open'
      expect(generic_work.file_sets.find { |fs| fs.label == uploaded_file2.file.filename }.visibility).to eq 'restricted'
      expect(uploaded_file1.reload.file_set_uri).not_to be_nil
    end
  end
end
