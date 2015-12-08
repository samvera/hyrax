require 'spec_helper'

describe Sufia::IngestLocalFileService do
  let(:user) { create(:user) }

  let(:work) do
    GenericWork.create!(title: ['test title']) do |w|
      w.apply_depositor_metadata(user)
    end
  end

  let(:files) { ["world.png", "image.jpg"] }
  let(:files_and_directories) { ["import"] }
  let(:upload_directory) { 'spec/mock_upload_directory' }
  let(:import_files_directory) { File.join(upload_directory, "import/files") }
  let(:import_metadata_directory) { File.join(upload_directory, "import/metadata") }

  before do
    Sufia.config.enable_local_ingest = true
    FileUtils.mkdir_p([import_files_directory, import_metadata_directory])
    FileUtils.copy(fixture_path + "/world.png", upload_directory)
    FileUtils.copy(fixture_path + "/image.jpg", upload_directory)
    FileUtils.copy(fixture_path + "/dublin_core_rdf_descMetadata.nt", import_metadata_directory)
    FileUtils.copy(fixture_path + "/icons.zip", import_files_directory)
    FileUtils.copy(fixture_path + "/Example.ogg", import_files_directory)
    allow_any_instance_of(User).to receive(:directory).and_return(upload_directory)
    allow(CharacterizeJob).to receive(:perform_later)
  end

  describe "#ingest_local_file" do
    subject { described_class.new(user) }
    let(:actor) { CurationConcerns::FileSetActor.new(nil, nil) }

    it "creates generic files for each file passed in" do
      # no need to save the files to Fedora we just want to know they were created
      allow_any_instance_of(FileSet).to receive(:save!).and_return(true)

      # allow random FileSets to be created
      allow(FileSet).to receive(:new).with({}).and_call_original

      # expect each file to be created
      expect(FileSet).to receive(:new).with(label: "world.png").and_call_original
      expect(FileSet).to receive(:new).with(label: "image.jpg").and_call_original

      # expect metadata to be applied to each file
      allow(CurationConcerns::FileSetActor).to receive(:new).and_return(actor)
      expect(actor).to receive(:create_metadata).twice

      # expect each file to be ingested
      expect(IngestLocalFileJob).to receive(:perform_later).with(nil, "spec/mock_upload_directory", "world.png", user.user_key)
      expect(IngestLocalFileJob).to receive(:perform_later).with(nil, "spec/mock_upload_directory", "image.jpg", user.user_key)
      subject.ingest_local_file(files, work.id)
    end

    it "processes files in subdirectories" do
      # no need to save the files to Fedora we just want to know they were created
      allow_any_instance_of(FileSet).to receive(:save!).and_return(true)

      # allow random FileSets to be created
      allow(FileSet).to receive(:new).with({}).and_call_original

      # expect each file to be created
      expect(FileSet).to receive(:new).with(label: "icons.zip").and_call_original
      expect(FileSet).to receive(:new).with(label: "Example.ogg").and_call_original
      expect(FileSet).to receive(:new).with(label: "dublin_core_rdf_descMetadata.nt").and_call_original

      # expect metadata to be applied to each file
      allow(CurationConcerns::FileSetActor).to receive(:new).and_return(actor)
      expect(actor).to receive(:create_metadata).exactly(3).times

      # expect each file to be ingested
      expect(IngestLocalFileJob).to receive(:perform_later).with(nil, "spec/mock_upload_directory", "import/files/icons.zip", user.user_key)
      expect(IngestLocalFileJob).to receive(:perform_later).with(nil, "spec/mock_upload_directory", "import/files/Example.ogg", user.user_key)
      expect(IngestLocalFileJob).to receive(:perform_later).with(nil, "spec/mock_upload_directory", "import/metadata/dublin_core_rdf_descMetadata.nt", user.user_key)

      subject.ingest_local_file(files_and_directories, work.id)
    end
  end

  describe "#logger" do
    context "by default" do
      subject { described_class.new(user).logger }
      it { is_expected.to eq(Rails.logger) }
    end
    context "when the logger is nil" do
      subject { described_class.new(user, nil).logger }
      it { is_expected.to be_kind_of(CurationConcerns::NullLogger) }
    end
    context "with my own logger" do
      let(:logger) { Logger.new(nil) }
      subject { described_class.new(user, logger).logger }
      it { is_expected.to be_kind_of(Logger) }
    end
  end
end
