require 'spec_helper'

describe Sufia::CreateWithFilesActor do
  let(:create_actor) { double('create actor', create: true,
                                              curation_concern: work,
                                              user: user) }
  let(:actor) { described_class.new(create_actor, uploaded_file_ids) }
  let(:user) { create(:user) }
  let(:uploaded_file1) { UploadedFile.create(user: user) }
  let(:uploaded_file2) { UploadedFile.create(user: user) }
  let(:work) { create(:generic_work, user: user) }
  let(:uploaded_file_ids) { [uploaded_file1.id, uploaded_file2.id] }

  before do
    allow(create_actor).to receive(:create).and_return(true)
  end

  context "when uploaded_file_ids belong to me" do
    it "attaches files" do
      expect(AttachFilesToWorkJob).to receive(:perform_later).with(GenericWork, [uploaded_file1, uploaded_file2])
      expect(actor.create).to be true
    end
  end

  context "when uploaded_file_ids don't belong to me" do
    let(:uploaded_file2) { UploadedFile.create }
    it "doesn't attach files" do
      expect(AttachFilesToWorkJob).not_to receive(:perform_later)
      expect(actor.create).to be false
    end
  end
end
