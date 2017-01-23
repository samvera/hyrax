describe BatchCreateJob do
  let(:user) { create(:user) }
  let(:log)  { create(:batch_create_operation, user: user) }

  before do
    allow(CharacterizeJob).to receive(:perform_later)
    allow(CurationConcerns.config.callback).to receive(:run)
    allow(CurationConcerns.config.callback).to receive(:set?).with(:after_batch_create_success).and_return(true)
    allow(CurationConcerns.config.callback).to receive(:set?).with(:after_batch_create_failure).and_return(true)
  end

  describe "#perform" do
    let(:upload1) { Sufia::UploadedFile.create(user: user, file: File.open(fixture_path + '/world.png')) }
    let(:upload2) { Sufia::UploadedFile.create(user: user, file: File.open(fixture_path + '/image.jp2')) }
    let(:title)          { { upload1.id.to_s => 'File One', upload2.id.to_s => 'File Two' } }
    let(:resource_types) { { upload1.id.to_s => 'Article',  upload2.id.to_s => 'Image'    } }
    let(:metadata)       { { keyword: [], model: 'GenericWork' } }
    let(:uploaded_files) { [upload1.id.to_s, upload2.id.to_s] }
    # let(:errors) { double(full_messages: "It's broke!") }
    let(:work)   { build(:generic_work) }
    let(:actor)  { double(curation_concern: work) }

    subject do
      described_class.perform_later(user,
                                    title,
                                    resource_types,
                                    uploaded_files,
                                    metadata,
                                    log)
    end

    it "updates work metadata" do
      expect(CurationConcerns::CurationConcern).to receive(:actor).with(an_instance_of(GenericWork), user).and_return(actor).twice
      expect(actor).to receive(:create).with(keyword: [], title: ['File One'], resource_type: ["Article"], uploaded_files: ['1']).and_return(true)
      expect(actor).to receive(:create).with(keyword: [], title: ['File Two'], resource_type: ["Image"], uploaded_files: ['2']).and_return(true)
      expect(CurationConcerns.config.callback).to receive(:run).with(:after_batch_create_success, user)
      subject
      expect(log.status).to eq 'pending'
      expect(log.reload.status).to eq 'success'
    end

    context "when permissions_attributes are passed" do
      let(:permissions) { { 'permissions_attributes' => [{ 'type' => 'group', 'name' => 'public', 'access' => 'read' }] } }
      let(:metadata) { super().merge(permissions) }
      it "sets the groups" do
        subject
        expect(GenericWork.last.read_groups).to include "public"
      end
    end

    context "when visibility is passed" do
      let(:metadata) { super().merge('visibility' => 'open') }
      it "sets public read access" do
        subject
        expect(GenericWork.last.reload.read_groups).to eq ['public']
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

    context "when multiple resource types are passed" do
      let(:resource_types) { { upload1.id.to_s => ['Image', 'Text'], upload2.id.to_s => ['Image', 'Text'] } }
      it "sets them all on the record" do
        subject
        resource_types = GenericWork.last.reload.resource_type
        expect(resource_types).to include 'Image'
        expect(resource_types).to include 'Text'
      end
    end
  end
end
