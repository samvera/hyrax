# frozen_string_literal: true
require 'wings'

RSpec.describe MigrateFilesToValkyrieJob, valkyrie_adapter: :freyja_adapter, perform_enqueued: [MigrateFilesToValkyrieJob] do
  let(:user)      { create(:user) }
  let(:file) { File.open(fixture_path + '/' + label) }
  let(:uploaded_file1) { build(:uploaded_file, file:) }
  let(:fedora_file_set) { create(:file_set, title: ['Some title'], label: label, content: file) }
  let(:label) { 'image.jpg' }

  let(:migrated_fileset) { Hyrax.persister.save(resource: fedora_file_set.valkyrie_resource) }
  let(:file_with_characterization) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = label
      f.height = '111'
      f.width = '222'
      f.file_size = '123456'
      f.format_label = ["Portable Network Graphics"]
      f.original_checksum = ['checksum123']
      f.save!
    end
  end

  before do
    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
    allow(fedora_file_set).to receive(:characterization_proxy).and_return(file_with_characterization)
    # allow(ActiveFedora::Base).to receive(:find).and_call_original
    # allow(ActiveFedora::Base).to receive(:find).with(migrated_fileset.original_file.file_identifier.to_s).and_return(file_with_characterization)
    # allow(FileSet).to receive(:find).with(fedora_file_set.id).and_return(fedora_file_set)
  end

  it "it migrates all derivatives along with a file" do
    described_class.perform_now(migrated_fileset)

    valkyrized_file_set = Hyrax.query_service.find_by(id: migrated_fileset.id)
    terms = FileSet.characterization_terms - [:alpha_channels, :original_checksum]
    terms.each do |t|
      expect(valkyrized_file_set.original_file.send(t)).to eq(fedora_file_set.characterization_proxy.send(t))
    end
    expect(valkyrized_file_set.original_file.checksum).to eq(fedora_file_set.characterization_proxy.original_checksum)
    expect(valkyrized_file_set.original_file.channels).to eq(fedora_file_set.characterization_proxy.alpha_channels)
  end
end
  