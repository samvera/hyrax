# frozen_string_literal: true
RSpec.describe Hyrax::CollectionsService, :clean_repo do
  let(:controller) { ::CatalogController.new }

  let(:context) do
    double(current_ability: Ability.new(user1),
           repository: controller.blacklight_config.repository,
           params: {},
           blacklight_config: controller.blacklight_config)
  end

  let(:service) { described_class.new(context) }
  let(:user1) { create(:user) }

  describe "#search_results" do
    subject { service.search_results(access) }

    let(:user2) { create(:user) }
    let!(:collection1) do
      valkyrie_create(:hyrax_collection, title: ['user1 created'], user: user1)
    end
    let!(:collection2) do
      valkyrie_create(:hyrax_collection, title: ['user2 shares manage access with user1'], user: user2,
                                         access_grants: [{
                                           agent_type: Hyrax::PermissionTemplateAccess::USER,
                                           agent_id: user1.user_key,
                                           access: Hyrax::PermissionTemplateAccess::MANAGE
                                         }])
    end
    let!(:collection3) do
      valkyrie_create(:hyrax_collection, title: ['user2 shares deposit access with user1'], user: user2,
                                         access_grants: [{
                                           agent_type: Hyrax::PermissionTemplateAccess::USER,
                                           agent_id: user1.user_key,
                                           access: Hyrax::PermissionTemplateAccess::DEPOSIT
                                         }])
    end
    let!(:collection4) do
      valkyrie_create(:hyrax_collection, title: ['user2 shares view access with user1'], user: user2,
                                         access_grants: [{
                                           agent_type: Hyrax::PermissionTemplateAccess::USER,
                                           agent_id: user1.user_key,
                                           access: Hyrax::PermissionTemplateAccess::VIEW
                                         }])
    end

    before do
      valkyrie_create(:hyrax_admin_set, read_groups: ['public']) # this should never be returned.
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

  describe "#all_search_results" do
    subject { service.all_search_results(access) }

    let(:user2) { create(:user) }
    let!(:collection1) do
      valkyrie_create(:hyrax_collection, title: ['user1 created'], user: user1)
    end
    let!(:collection2) do
      valkyrie_create(:hyrax_collection, title: ['user2 shares manage access with user1'], user: user2,
                                         access_grants: [{
                                           agent_type: Hyrax::PermissionTemplateAccess::USER,
                                           agent_id: user1.user_key,
                                           access: Hyrax::PermissionTemplateAccess::MANAGE
                                         }])
    end
    let!(:collection3) do
      valkyrie_create(:hyrax_collection, title: ['user2 shares deposit access with user1'], user: user2,
                                         access_grants: [{
                                           agent_type: Hyrax::PermissionTemplateAccess::USER,
                                           agent_id: user1.user_key,
                                           access: Hyrax::PermissionTemplateAccess::DEPOSIT
                                         }])
    end

    before do
      valkyrie_create(:hyrax_admin_set, read_groups: ['public']) # this should never be returned.
    end

    context "with deposit access" do
      let(:access) { :deposit }

      it "returns all collections the user can deposit into" do
        expect(subject.map(&:id)).to match_array [collection1.id, collection2.id, collection3.id]
      end
    end

    context "when total matches exceed the configured page size" do
      before do
        allow(Hyrax.config).to receive(:solr_rows_per_request).and_return(1)
      end

      let(:access) { :deposit }

      it "pages through all matches" do
        expect(subject.map(&:id)).to match_array [collection1.id, collection2.id, collection3.id]
      end
    end
  end
end
