require 'spec_helper'

describe Sufia::IngestLocalFileService do
  let(:user) { create(:user) }

  let(:work) do
    GenericWork.create!(title: ['test title']) do |w|
      w.apply_depositor_metadata(user)
    end
  end

  let(:upload_set) { UploadSet.create! }
  let(:upload_set_id) { upload_set.id }
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

    it "creates generic files for each file passed in" do
      expect {
        subject.ingest_local_file(files, work.id, upload_set_id)
      }.to change(FileSet, :count).by(2)
      created_files = FileSet.all
      created_files.each { |f| expect(f.generic_works).to include work }
    end

    it "processes files in subdirectories" do
      expect {
        subject.ingest_local_file(files_and_directories, work.id, upload_set_id)
      }.to change(FileSet, :count).by(3)
      expected_titles = ['dublin_core_rdf_descMetadata.nt', 'icons.zip', 'Example.ogg']
      created_files = FileSet.all
      created_files.each do |f|
        expect(expected_titles).to include f.title.first
      end
    end
  end
end
