RSpec.describe BatchCreateJob do
  let(:user) { create(:user) }
  let(:operation) { create(:batch_create_operation, user: user) }
  let(:child_operation) { double }

  describe "#perform" do
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:file2) { File.open(fixture_path + '/image.jp2') }
    let(:upload1) { Hyrax::UploadedFile.create(user: user, file: file1) }
    let(:upload2) { Hyrax::UploadedFile.create(user: user, file: file2) }
    let(:title) { { upload1.id.to_s => 'File One', upload2.id.to_s => 'File Two' } }
    let(:resource_types) { { upload1.id.to_s => 'Article', upload2.id.to_s => 'Image' } }
    let(:metadata) { { keyword: [], model: 'GenericWork' } }
    let(:uploaded_files) { [upload1.id.to_s, upload2.id.to_s] }

    subject do
      described_class.perform_now(user,
                                  title,
                                  resource_types,
                                  uploaded_files,
                                  metadata,
                                  operation)
    end

    before do
      allow(Hyrax::Operation).to receive(:create!).with(user: user,
                                                        operation_type: "Create Work",
                                                        parent: operation).and_return(child_operation)
    end

    it "spawns CreateWorkJobs for each work" do
      expect(CreateWorkJob).to receive(:perform_later).with(user,
                                                            "GenericWork",
                                                            {
                                                              keyword: [],
                                                              title: ['File One'],
                                                              resource_type: ["Article"],
                                                              uploaded_files: [upload1.id.to_s]
                                                            },
                                                            child_operation).and_return(true)
      expect(CreateWorkJob).to receive(:perform_later).with(user,
                                                            "GenericWork",
                                                            {
                                                              keyword: [],
                                                              title: ['File Two'],
                                                              resource_type: ["Image"],
                                                              uploaded_files: [upload2.id.to_s]
                                                            },
                                                            child_operation).and_return(true)
      subject
    end

    context "when multiple resource types are passed for each work." do
      let(:resource_types) { { upload1.id.to_s => ['Article', 'Text'], upload2.id.to_s => ['Image', 'Text'] } }

      it "spawns CreateWorkJobs for each work" do
        expect(CreateWorkJob).to receive(:perform_later).with(user,
                                                              "GenericWork",
                                                              {
                                                                keyword: [],
                                                                title: ['File One'],
                                                                resource_type: ["Article", 'Text'],
                                                                uploaded_files: [upload1.id.to_s]
                                                              },
                                                              child_operation).and_return(true)
        expect(CreateWorkJob).to receive(:perform_later).with(user,
                                                              "GenericWork",
                                                              {
                                                                keyword: [],
                                                                title: ['File Two'],
                                                                resource_type: ["Image", 'Text'],
                                                                uploaded_files: [upload2.id.to_s]
                                                              },
                                                              child_operation).and_return(true)
        subject
      end
    end
  end
end
