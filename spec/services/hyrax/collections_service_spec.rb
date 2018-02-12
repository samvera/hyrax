RSpec.describe Hyrax::CollectionsService do
  let(:controller) { ::CatalogController.new }
  let(:context) do
    double(current_ability: Ability.new(user1),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end

  let(:service) { described_class.new(context) }
  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:ability) { Ability.new(user1) }

  let(:col1_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-1-own", "title_tesim" => ["user1 created"], "title_sim" => ["user1 created"],
      "edit_access_person_ssim" => [user1.user_key] }
  end
  let!(:col1_pt) { create(:permission_template, source_id: col1_doc[:id], source_type: 'collection', manage_users: [user1.user_key]) }
  let(:col2_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-2-mgr", "title_tesim" => ["user2 shares manage access with user1"], "title_sim" => ["user2 shares manage access with user1"],
      "edit_access_person_ssim" => [user2.user_key, user1.user_key] }
  end
  let!(:col2_pt) { create(:permission_template, source_id: col2_doc[:id], source_type: 'collection', manage_users: [user2.user_key, user1.user_key]) }
  let(:col3_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-3-dep", "title_tesim" => ["user2 shares deposit access with user1"], "title_sim" => ["user2 shares deposit access with user1"],
      "edit_access_person_ssim" => [user2.user_key], "read_access_person_ssim" => [user1.user_key] }
  end
  let!(:col3_pt) { create(:permission_template, source_id: col3_doc[:id], source_type: 'collection', manage_users: [user2.user_key], deposit_users: [user1.user_key]) }
  let(:col4_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-4-view", "title_tesim" => ["user2 shares view access with user1"], "title_sim" => ["user2 shares view access with user1"],
      "edit_access_person_ssim" => [user2.user_key], "read_access_person_ssim" => [user1.user_key] }
  end
  let!(:col4_pt) { create(:permission_template, source_id: col4_doc[:id], source_type: 'collection', manage_users: [user2.user_key], view_users: [user1.user_key]) }

  before do
    ActiveFedora::SolrService.add(col1_doc, commit: true)
    ActiveFedora::SolrService.add(col2_doc, commit: true)
    ActiveFedora::SolrService.add(col3_doc, commit: true)
    ActiveFedora::SolrService.add(col4_doc, commit: true)

    allow(controller).to receive(:current_ability).and_return(ability)
  end

  describe "#search_results", :clean_repo do
    subject { service.search_results(access) }

    context "with read access" do
      let(:access) { :read }

      it "returns three collections" do
        expect(subject.map(&:id)).to match_array [col1_doc[:id], col2_doc[:id], col3_doc[:id], col4_doc[:id]]
      end
    end

    context "with edit access" do
      let(:access) { :edit }

      it "returns two collections" do
        expect(subject.map(&:id)).to match_array [col1_doc[:id], col2_doc[:id]]
      end
    end

    context "with deposit access" do
      let(:access) { :deposit }

      it "returns one collections" do
        expect(subject.map(&:id)).to match_array [col1_doc[:id], col2_doc[:id], col3_doc[:id]]
      end
    end
  end
end
