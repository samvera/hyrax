require 'spec_helper'

describe BatchCreateJob do
  let(:user) { create(:user) }

  before do
    allow(CharacterizeJob).to receive(:perform_later)
    allow(CurationConcerns.config.callback).to receive(:run)
    allow(CurationConcerns.config.callback).to receive(:set?)
      .with(:after_batch_create_success)
      .and_return(true)
    allow(CurationConcerns.config.callback).to receive(:set?)
      .with(:after_batch_create_failure)
      .and_return(true)
  end

  describe "#perform" do
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:file2) { File.open(fixture_path + '/image.jp2') }
    let(:upload1) {  UploadedFile.create(user: user, file: file1) }
    let(:upload2) {  UploadedFile.create(user: user, file: file2) }
    let(:title) { { upload1.id => 'File One', upload2.id => 'File Two' } }
    let(:metadata) { { tag: [] } }
    let(:uploaded_files) { [upload1.id, upload2.id] }
    let(:errors) { double(full_messages: "It's broke!") }
    let(:work) { double(errors: errors) }
    let(:actor) { double(curation_concern: work) }

    subject { described_class.perform_now(user, title, uploaded_files, metadata) }

    it "updates work metadata" do
      expect(CurationConcerns::CurationConcern::ActorStack).to receive(:new).and_return(actor).twice
      expect(actor).to receive(:create).with(tag: [], title: ['File One'], uploaded_files: [1]).and_return(true)
      expect(actor).to receive(:create).with(tag: [], title: ['File Two'], uploaded_files: [2]).and_return(true)
      expect(CurationConcerns.config.callback).to receive(:run).with(:after_batch_create_success, user)
      subject
    end

    context "when permissions_attributes are passed" do
      let(:metadata) do
        { "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }] }
      end
      it "sets the groups" do
        subject
        work = GenericWork.last
        expect(work.read_groups).to include "public"
      end
    end

    context "when visibility is passed" do
      let(:metadata) do
        { "visibility" => 'open' }
      end
      it "sets public read access" do
        subject
        work = GenericWork.last
        expect(work.reload.read_groups).to eq ['public']
      end
    end

    context "when user does not have permission to edit all of the works" do
      it "sends the failure message" do
        expect(CurationConcerns::CurationConcern::ActorStack).to receive(:new).and_return(actor).twice
        expect(actor).to receive(:create).and_return(true, false)
        expect(CurationConcerns.config.callback).to receive(:run).with(:after_batch_create_failure, user)
        subject
      end
    end
  end
end
