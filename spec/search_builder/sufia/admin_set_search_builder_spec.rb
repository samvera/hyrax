require 'spec_helper'

describe Sufia::AdminSetSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:ability) do
    instance_double(Ability,
                    admin?: false,
                    user_groups: [],
                    current_user: user)
  end
  let(:user) { create(:user) }
  let(:builder) { described_class.new(context, access) }
  subject { builder.to_h }

  context "when searching for read access" do
    let(:access) { :read }
    it 'is successful' do
      expect(subject['fq']).to eq ["edit_access_person_ssim:#{user.user_key} OR discover_access_person_ssim:#{user.user_key} OR read_access_person_ssim:#{user.user_key}", "{!terms f=has_model_ssim}AdminSet"]
    end
  end

  context "when searching for deposit access" do
    let(:access) { :deposit }
    let(:permission_template1) { create(:permission_template, admin_set_id: 7) }
    let(:permission_template2) { create(:permission_template, admin_set_id: 8) }
    let(:permission_template3) { create(:permission_template, admin_set_id: 9) }

    before do
      create(:permission_template_access,
             permission_template: permission_template1,
             agent_type: 'user',
             agent_id: user.user_key,
             access: 'deposit')
      create(:permission_template_access,
             permission_template: permission_template2,
             agent_type: 'user',
             agent_id: user.user_key,
             access: 'manage')
      create(:permission_template_access,
             permission_template: permission_template3,
             agent_type: 'user',
             agent_id: user.user_key,
             access: 'view')
    end

    it 'is successful' do
      expect(subject['fq']).to eq ["{!terms f=id}7,8", "{!terms f=has_model_ssim}AdminSet"]
    end
  end
end
