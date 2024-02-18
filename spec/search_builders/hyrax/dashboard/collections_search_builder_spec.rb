# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::CollectionsSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user,
           search_state_class: nil)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user, groups: 'registered') }
  let(:builder) { described_class.new(context) }

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq(Hyrax::ModelRegistry.admin_set_classes + Hyrax::ModelRegistry.collection_classes) }
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
      expect(solr_params[:fq].first).to match(%r{\(-_query_:\"{!raw f=depositor_ssim}#{user.user_key}\" OR })
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
    let(:user2) { create(:user) }
    let!(:collection) { valkyrie_create(:hyrax_collection, user: user2, access_grants: grants) }

    subject { builder.gated_discovery_filters }

    context "user has manage access" do
      let(:grants) do
        [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
           agent_id: user.user_key,
           access: Hyrax::PermissionTemplateAccess::MANAGE }]
      end

      it { is_expected.to include ["{!terms f=id}#{collection.id}"] }
    end

    context "user has deposit access" do
      let(:grants) do
        [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
           agent_id: user.user_key,
           access: Hyrax::PermissionTemplateAccess::DEPOSIT }]
      end

      it { is_expected.to include ["{!terms f=id}#{collection.id}"] }
    end

    context "user has view access" do
      let(:grants) do
        [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
           agent_id: user.user_key,
           access: Hyrax::PermissionTemplateAccess::VIEW }]
      end

      it { is_expected.not_to include ["{!terms f=id}#{collection.id}"] }
    end

    context "does not include registered group for read access" do
      let(:grants) do
        [{ agent_type: Hyrax::PermissionTemplateAccess::GROUP,
           agent_id: 'registered',
           access: Hyrax::PermissionTemplateAccess::VIEW }]
      end

      it { is_expected.not_to include ["{!terms f=id}#{collection.id}"] }
    end

    context "does not include public group for read access" do
      let(:grants) do
        [{ agent_type: Hyrax::PermissionTemplateAccess::GROUP,
           agent_id: 'public',
           access: Hyrax::PermissionTemplateAccess::VIEW }]
      end

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
      let(:grants) do
        [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
           agent_id: user.user_key,
           access: Hyrax::PermissionTemplateAccess::DEPOSIT },
         { agent_type: Hyrax::PermissionTemplateAccess::GROUP,
           agent_id: 'registered',
           access: Hyrax::PermissionTemplateAccess::VIEW }]
      end

      it { is_expected.to include ["{!terms f=id}#{collection.id}"] }
    end
  end
end
