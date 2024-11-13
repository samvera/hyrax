# frozen_string_literal: true

require 'freyja/persister'
RSpec.describe MigrateResourcesJob, index_adapter: :solr_index, valkyrie_adapter: :freyja_adapter do
  let(:af_file_set) { create(:file_set, title: ['TestFS']) }

  let!(:af_admin_set) do
    as = AdminSet.new(title: ['AF Admin Set'])
    as.save
    AdminSet.find(as.id)
  end

  describe '#perform' do
    it "migrates admin sets to valkyrie", active_fedora_to_valkyrie: true do
      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_admin_set.id.to_s)).to be_nil

      MigrateResourcesJob.perform_now(ids: [af_admin_set.id])
      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_admin_set.id.to_s)).to be_present
    end

    it "migrates a file set by its id", active_fedora_to_valkyrie: true do
      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_file_set.id.to_s)).to be_nil

      MigrateResourcesJob.perform_now(ids: [af_file_set.id])

      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_file_set.id.to_s)).to be_present
    end
  end
end
