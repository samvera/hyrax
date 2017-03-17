require 'spec_helper'

RSpec.describe Hyrax::AdminSetSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:user_groups) { [] }
  let(:ability) do
    instance_double(Ability,
                    admin?: false,
                    user_groups: user_groups,
                    current_user: user)
  end
  let(:user) { create(:user) }
  let(:builder) { described_class.new(context, access) }

  describe '#filter_models' do
    before { builder.filter_models(solr_params) }
    let(:access) { :read }
    let(:solr_params) { { fq: [] } }

    it 'adds AdminSet to query' do
      expect(solr_params[:fq].first).to include('{!terms f=has_model_ssim}AdminSet')
    end
  end

  describe "#gated_discovery_filters" do
    subject { builder.gated_discovery_filters }

    context "when access is :deposit" do
      let(:access) { :deposit }
      let(:admin_set) { create(:admin_set) }
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }

      context "and user has access" do
        before do
          create(:permission_template_access,
                 permission_template: permission_template,
                 agent_type: 'user',
                 agent_id: user.user_key,
                 access: 'deposit')
        end

        it { is_expected.to eq ["{!terms f=id}#{admin_set.id}"] }
      end

      context "and group has access" do
        let(:user_groups) { ['registered'] }
        before do
          create(:permission_template_access,
                 permission_template: permission_template,
                 agent_type: 'group',
                 agent_id: 'registered',
                 access: 'deposit')
        end

        it { is_expected.to eq ["{!terms f=id}#{admin_set.id}"] }
      end

      context "and user has no access" do
        let(:user_groups) { ['registered'] }
        it { is_expected.to eq ["{!terms f=id}"] }
      end
    end
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }
    it { is_expected.to include :filter_models }
  end

  describe "#to_h" do
    subject { builder.to_h }

    context "when searching for read access" do
      let(:access) { :read }
      it 'is successful' do
        expect(subject['fq']).to eq ["edit_access_person_ssim:#{user.user_key} OR " \
                                       "discover_access_person_ssim:#{user.user_key} OR " \
                                       "read_access_person_ssim:#{user.user_key}",
                                     "{!terms f=has_model_ssim}AdminSet"]
      end
    end

    context "when searching for deposit access" do
      let(:access) { :deposit }
      let(:permission_template1) { create(:permission_template, admin_set_id: 7) }
      let(:permission_template2) { create(:permission_template, admin_set_id: 8) }
      let(:permission_template3) { create(:permission_template, admin_set_id: 9) }

      before do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template1,
               agent_type: 'user',
               agent_id: user.user_key,
               access: 'deposit')
        create(:permission_template_access,
               :manage,
               permission_template: permission_template2,
               agent_type: 'user',
               agent_id: user.user_key)
        create(:permission_template_access,
               :view,
               permission_template: permission_template3,
               agent_type: 'user',
               agent_id: user.user_key)
      end

      it 'is successful' do
        expect(subject['fq']).to eq ["{!terms f=id}7,8", "{!terms f=has_model_ssim}AdminSet"]
      end
    end
  end
end
