# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::CollectionsSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { build(:user, groups: 'registered') }
  let(:builder) { described_class.new(context) }

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq([AdminSet, Hyrax::AdministrativeSet, ::Collection, Hyrax.config.collection_class].uniq) }
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :show_only_managed_collections_for_non_admins }
  end

  describe '#discovery_permissions' do
    subject { builder.discovery_permissions }

    it { is_expected.to eq %w[edit read] }
  end

  describe "#show_only_managed_collections_for_non_admins" do
    let(:solr_params) { Blacklight::Solr::Request.new }

    before do
      builder.show_only_managed_collections_for_non_admins(solr_params)
    end

    it "has filter that excludes depositor" do
      expect(solr_params[:fq]).to eq ["(-_query_:\"{!raw f=depositor_ssim}#{user.user_key}\" OR -(_query_:\"{!raw f=has_model_ssim}AdminSet\" AND _query_:\"{!raw f=creator_ssim}#{user.user_key}\"))"]
    end

    context "as admin" do
      # Overrides the user sent to builder via context, above.
      let(:user) { create(:user, groups: 'admin') }

      it "does nothing" do
        expect(solr_params[:fq].to_a).to eq []
      end
    end
  end

  describe "#gated_discovery_filters" do
    let(:user2) { build(:user) }
    let!(:collection) { build(:collection_lw, user: user2, with_permission_template: permissions, with_solr_document: true) }

    subject { builder.gated_discovery_filters }

    context "user has manage access" do
      let(:permissions) { { manage_users: [user] } }

      it { is_expected.to include ["{!terms f=id}#{collection.id}"] }
    end

    context "user has deposit access" do
      let(:permissions) { { deposit_users: [user] } }

      it { is_expected.to include ["{!terms f=id}#{collection.id}"] }
    end

    context "user has view access" do
      let(:permissions) { { view_users: [user] } }

      it { is_expected.not_to include ["{!terms f=id}#{collection.id}"] }
    end

    context "does not include registered group for read access" do
      let(:permissions) { { view_groups: ['registered'] } }

      it { is_expected.not_to include ["{!terms f=id}#{collection.id}"] }
    end

    context "does not include public group for read access" do
      let(:permissions) { { view_groups: ['public'] } }

      let(:expected_discovery_filters) do
        # all filters except no additional ids added for deposit collections
        [
          ["({!terms f=edit_access_group_ssim}public,registered)"],
          ["edit_access_person_ssim:#{user.user_key}", "read_access_person_ssim:#{user.user_key}"]
        ]
      end

      it { is_expected.to eq expected_discovery_filters }
    end

    context "user has deposit access and registered has deposit access" do
      # make sure that having registered deposit access, which isn't included, doesn't
      # remove the user specific deposit access
      let(:permissions) { { deposit_users: [user], view_groups: ['registered'] } }

      it { is_expected.to include ["{!terms f=id}#{collection.id}"] }
    end
  end
end
