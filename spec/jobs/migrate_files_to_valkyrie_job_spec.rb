# frozen_string_literal: true
require 'wings'

RSpec.describe MigrateFilesToValkyrieJob, index_adapter: :solr_index, valkyrie_adapter: :freyja_adapter, perform_enqueued: [MigrateFilesToValkyrieJob] do
  let(:user)      { create(:user) }
  let(:content) { File.open(fixture_path + '/' + label) }
  let(:uploaded_file1) { build(:uploaded_file, file:) }
  let(:fedora_file_set) { create(:file_set, title: ['Some title'], label: label, content: content) }
  let!(:pcdm_file) do pcdm_file = fedora_file_set.files.first
    pcdm_file.content = 'foo'
    pcdm_file.original_name = label
    pcdm_file.height = '111'
    pcdm_file.width = '222'
    pcdm_file.file_size = '123456'
    pcdm_file.format_label = ["Portable Network Graphics"]
    pcdm_file.original_checksum = ['checksum123']
    pcdm_file.save!
    pcdm_file
  end
  let(:label) { 'image.jpg' }
  let(:wings_file_set) { Hyrax.query_service.find_by(id: fedora_file_set.id) }
  let(:migrated_file_set) { Hyrax.persister.save(resource: wings_file_set) }

  before do
    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
  end

  it "it migrates all derivatives along with a file" do
    described_class.perform_now(migrated_file_set)

    valkyrized_file_set = Hyrax.query_service.find_by(id: migrated_file_set.id)
    described_class.new.attribute_mapping.each do |k, v|
      expect(valkyrized_file_set.original_file.send(k)).to match_array(pcdm_file.send(v))
    end
    solr_doc = Hyrax.index_adapter.connection.get("select", params: { q: "id:#{valkyrized_file_set.id.to_s}" })["response"]["docs"].first
    expect(solr_doc['width_is']).to eq(222)
  end
end
