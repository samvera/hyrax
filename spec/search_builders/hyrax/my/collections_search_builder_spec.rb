RSpec.describe Hyrax::My::CollectionsSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user) }
  let(:builder) { described_class.new(context) }

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq([AdminSet, Collection]) }
  end

  describe '#discovery_permissions' do
    subject { builder.discovery_permissions }

    it { is_expected.to eq(['edit']) }
  end

  describe "#gated_discovery_filters" do
    subject { builder.gated_discovery_filters }

    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }

    context "user has manage access" do
      before do
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: user.user_key,
               access: 'manage')
      end

      it { is_expected.to include ["{!terms f=id}#{admin_set.id}"] }
    end

    context "group has manage access" do
      before do
        create(:permission_template_access,
               permission_template: permission_template,
               agent_type: 'group',
               agent_id: 'registered',
               access: 'manage')
      end

      it { is_expected.to include ["{!terms f=id}#{admin_set.id}"] }
    end

    context "user has no access" do
      it { is_expected.to eq [["({!terms f=edit_access_group_ssim}public,registered)"], ["edit_access_person_ssim:#{user.user_key}"]] }
    end
  end
end
