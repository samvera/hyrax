RSpec.describe Hyrax::Dashboard::CollectionsSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user, groups: 'registered') }
  let(:builder) { described_class.new(context) }

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq([AdminSet, Collection]) }
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
    subject { builder.show_only_managed_collections_for_non_admins(solr_params) }

    let(:solr_params) { Blacklight::Solr::Request.new }

    it "has filter that excludes depositor" do
      subject
      expect(solr_params[:fq]).to eq ["(-_query_:\"{!raw f=depositor_ssim}#{user.user_key}\" OR -(_query_:\"{!raw f=has_model_ssim}AdminSet\" AND _query_:\"{!raw f=creator_ssim}#{user.user_key}\"))"]
    end

    context "as admin" do
      let(:user) { create(:user, groups: 'admin') }

      it "does nothing" do
        subject
        expect(solr_params[:fq]).to eq []
      end
    end
  end

  describe "#gated_discovery_filters" do
    subject { builder.gated_discovery_filters }

    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }

    context "user has deposit access" do
      before do
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: user.user_key,
               access: 'deposit')
      end

      it { is_expected.to include ["{!terms f=id}#{admin_set.id}"] }
    end

    context "group has deposit access" do
      before do
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'group',
               agent_id: 'registered',
               access: 'deposit')
      end

      it { is_expected.to include ["{!terms f=id}#{admin_set.id}"] }
    end

    context "does not include public group for read access" do
      let(:expected_discovery_filters) do
        [
          ["({!terms f=edit_access_group_ssim}public,registered)"],
          ["edit_access_person_ssim:#{user.user_key}", "read_access_person_ssim:#{user.user_key}"]
        ]
      end

      it { is_expected.to eq expected_discovery_filters }
    end
  end
end
