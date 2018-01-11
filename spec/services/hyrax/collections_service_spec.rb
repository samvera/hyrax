RSpec.describe Hyrax::CollectionsService do
  let(:controller) { ::CatalogController.new }

  let(:context) do
    double(current_ability: Ability.new(user1),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end

  let(:service) { described_class.new(context) }
  let(:user1) { create(:user) }

  describe "#search_results", :clean_repo do
    subject { service.search_results(access) }

    let(:user2) { create(:user) }
    let!(:collection1) { create(:private_collection, id: 'col-1-own', title: ['user1 created'], user: user1, create_access: true) }
    let!(:collection2) do
      create(:private_collection, id: 'col-2-mgr', title: ['user2 shares manage access with user1'], user: user2,
                                  with_permission_template: { manage_users: [user1] }, create_access: true)
    end
    let!(:collection3) do
      create(:private_collection, id: 'col-3-dep', title: ['user2 shares deposit access with user1'], user: user2,
                                  with_permission_template: { deposit_users: [user1] }, create_access: true)
    end
    let!(:collection4) do
      create(:private_collection, id: 'col-4-view', title: ['user2 shares view access with user1'], user: user2,
                                  with_permission_template: { view_users: [user1] }, create_access: true)
    end

    before do
      create(:admin_set, id: 'as-1', read_groups: ['public']) # this should never be returned.
    end

    context "with read access" do
      let(:access) { :read }

      it "returns three collections" do
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
