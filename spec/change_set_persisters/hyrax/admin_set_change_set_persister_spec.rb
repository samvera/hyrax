# frozen_string_literals: true

RSpec.describe Hyrax::AdminSetChangeSetPersister, type: :model do
  subject(:change_set_persister) do
    described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
  end

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set) { Hyrax::AdminSetChangeSet.new(admin_set) }

  describe "#destroy" do
    let(:admin_set) { create_for_repository(:admin_set, title: ['Some title']) }

    context "with member works" do
      let!(:gf1) { create_for_repository(:work, admin_set_id: admin_set.id) }
      let!(:gf2) { create_for_repository(:work, admin_set_id: admin_set.id) }

      before do
        change_set_persister.delete(change_set: change_set)
      end

      it "does not delete adminset or member works" do
        expect(change_set.errors.full_messages).to eq ["Administrative set cannot be deleted as it is not empty"]
        expect(Hyrax::Queries.exists?(admin_set.id)).to be true
        expect(Hyrax::Queries.exists?(gf1.id)).to be true
        expect(Hyrax::Queries.exists?(gf2.id)).to be true
      end
    end

    context "with no member works" do
      before do
        change_set_persister.delete(change_set: change_set)
      end

      it "deletes the adminset" do
        expect(Hyrax::Queries.exists?(admin_set.id)).to be false
      end
    end

    context "is default adminset" do
      let(:admin_set) { create_for_repository(:admin_set, id: AdminSet::DEFAULT_ID, title: ['Some title']) }

      before do
        change_set_persister.delete(change_set: change_set)
      end

      it "does not delete the adminset" do
        expect(change_set.errors.full_messages).to eq ["Administrative set cannot be deleted as it is the default set"]
        expect(Hyrax::Queries.exists?(Valkyrie::ID.new(AdminSet::DEFAULT_ID))).to be true
      end
    end
  end

  describe '.after_destroy' do
    let!(:admin_set) { create_for_repository(:admin_set, with_permission_template: true) }

    it 'will destroy the associated permission template' do
      expect { change_set_persister.delete(change_set: change_set) }.to change { Hyrax::PermissionTemplate.count }.by(-1)
    end
  end
end
