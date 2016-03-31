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
  end

  describe "#ingest_local_file" do
    subject { described_class.new(user) }
    let(:actor) { CurationConcerns::FileSetActor.new(nil, nil) }
    let(:fileset) { object_double(FileSet.new, id: 'demoid') }

    before do
      allow(user).to receive(:directory).and_return(upload_directory)
      allow(CharacterizeJob).to receive(:perform_later)

      allow(FileSet).to receive(:new).and_return(fileset)
      allow(fileset).to receive(:save!)
      allow(fileset).to receive(:relative_path=)

      allow(CurationConcerns::FileSetActor).to receive(:new).and_return(actor)
    end

    it "creates generic files for each file passed in" do
      # expect a FileSet per file to be created
      expect(FileSet).to receive(:new).with(label: "world.png")
      expect(FileSet).to receive(:new).with(label: "image.jpg")

      # expect metadata to be applied to each file
      expect(actor).to receive(:create_metadata).twice

      # expect each file to be ingested
      expect(IngestLocalFileJob).to receive(:perform_later).with(fileset, "spec/mock_upload_directory", "world.png", user)
      expect(IngestLocalFileJob).to receive(:perform_later).with(fileset, "spec/mock_upload_directory", "image.jpg", user)
      subject.ingest_local_file(files, work.id)
    end

    it "processes files in subdirectories" do
      # expect each file to be created
      expect(FileSet).to receive(:new).with(label: "icons.zip")
      expect(FileSet).to receive(:new).with(label: "Example.ogg")
      expect(FileSet).to receive(:new).with(label: "dublin_core_rdf_descMetadata.nt")

      # expect metadata to be applied to each file
      expect(actor).to receive(:create_metadata).exactly(3).times

      # expect each file to be ingested
      expect(IngestLocalFileJob).to receive(:perform_later).with(fileset, "spec/mock_upload_directory", "import/files/icons.zip", user)
      expect(IngestLocalFileJob).to receive(:perform_later).with(fileset, "spec/mock_upload_directory", "import/files/Example.ogg", user)
      expect(IngestLocalFileJob).to receive(:perform_later).with(fileset, "spec/mock_upload_directory", "import/metadata/dublin_core_rdf_descMetadata.nt", user)

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
