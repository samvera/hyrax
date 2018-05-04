RSpec.describe Hyrax::CollectionsService do
  let(:controller) { ::CatalogController.new }

  let(:context) do
    double(current_ability: Ability.new(user1),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end

  let(:service) { described_class.new(context) }
  let(:user1) { build(:user) }

  describe "#search_results", :clean_repo do
    subject { service.search_results(access) }

    let(:user2) { build(:user) }
    let!(:collection1) do
      build(:private_collection_lw, id: 'col-1-own', title: ['user1 created'], user: user1,
                                    with_permission_template: true, with_solr_document: true)
    end
    let!(:collection2) do
      build(:private_collection_lw, id: 'col-2-mgr', title: ['user2 shares manage access with user1'], user: user2,
                                    with_permission_template: { manage_users: [user1] }, with_solr_document: true)
    end
    let!(:collection3) do
      build(:private_collection_lw, id: 'col-3-dep', title: ['user2 shares deposit access with user1'], user: user2,
                                    with_permission_template: { deposit_users: [user1] }, with_solr_document: true)
    end
    let!(:collection4) do
      build(:private_collection_lw, id: 'col-4-view', title: ['user2 shares view access with user1'], user: user2,
                                    with_permission_template: { view_users: [user1] }, with_solr_document: true)
    end

    before do
      create(:admin_set, id: 'as-1', read_groups: ['public']) # this should never be returned.
    end

    context "with read access" do
      let(:access) { :read }

      it "returns four collections" do
        expect(subject.map(&:id)).to match_array [collection1.id, collection2.id, collection3.id, collection4.id]
      end
    end

    context "with edit access" do
      let(:access) { :edit }

      it "returns two collections" do
        expect(subject.map(&:id)).to match_array [collection1.id, collection2.id]
      end
    end

    context "with deposit access" do
      let(:access) { :deposit }

      it "returns one collections" do
        expect(subject.map(&:id)).to match_array [collection1.id, collection2.id, collection3.id]
      end
    end
  end
end
