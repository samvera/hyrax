describe BatchCreateJob do
  let(:user) { create(:user) }
  let(:log) { create(:batch_create_operation, user: user) }

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
    let(:upload1) { Sufia::UploadedFile.create(user: user, file: file1) }
    let(:upload2) { Sufia::UploadedFile.create(user: user, file: file2) }
    let(:title) { { upload1.id.to_s => 'File One', upload2.id.to_s => 'File Two' } }
    let(:resource_types) { { upload1.id.to_s => 'Article', upload2.id.to_s => 'Image' } }
    let(:metadata) { { keyword: [] } }
    let(:uploaded_files) { [upload1.id.to_s, upload2.id.to_s] }
    let(:errors) { double(full_messages: "It's broke!") }
    let(:work) { double(errors: errors) }
    let(:actor) { double(curation_concern: work) }

    subject { described_class.perform_later(user,
                                            title,
                                            resource_types,
                                            uploaded_files,
                                            metadata,
                                            log) }

    it "updates work metadata" do
      expect(CurationConcerns::CurationConcern).to receive(:actor).and_return(actor).twice
      expect(actor).to receive(:create).with(keyword: [], title: ['File One'], resource_type: ["Article"], uploaded_files: ['1']).and_return(true)
      expect(actor).to receive(:create).with(keyword: [], title: ['File Two'], resource_type: ["Image"], uploaded_files: ['2']).and_return(true)
      expect(CurationConcerns.config.callback).to receive(:run).with(:after_batch_create_success, user)
      subject
      expect(log.status).to eq 'pending'
      expect(log.reload.status).to eq 'success'
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
        expect(CurationConcerns::CurationConcern).to receive(:actor).and_return(actor).twice
        expect(actor).to receive(:create).and_return(true, false)
        expect(CurationConcerns.config.callback).to receive(:run).with(:after_batch_create_failure, user)
        subject
        expect(log.reload.status).to eq 'failure'
      end
    end
  end
end
