require 'spec_helper'

RSpec.describe Sufia::Admin::PermissionTemplatesController do
  routes { Sufia::Engine.routes }
  before do
    sign_in create(:user)
  end
  let(:sufia) { Sufia::Engine.routes.url_helpers }

  context "without admin privleges" do
    describe "update" do
      let(:permission_template) { create(:permission_template) }

      it "is unauthorized" do
        put :update, params: { id: permission_template, admin_set_id: 999 }
        expect(response).to be_unauthorized
      end
    end
  end

  context "when signed in as an admin" do
    describe "update" do
      let(:admin_set) { create(:admin_set) }
      let!(:permission_template) { Sufia::PermissionTemplate.create!(admin_set_id: admin_set.id) }
      let(:input_params) do
        { admin_set_id: admin_set.id,
          sufia_permission_template: {
            access_grants_attributes: [
              { "agent_type" => "Person", "agent_id" => "bob", "access" => "View" }
            ]
          } }
      end

      it "is successful" do
        expect(controller).to receive(:authorize!).with(:update, permission_template)
        expect do
          put :update, params: input_params
        end.to change { permission_template.access_grants.count }.by(1)
        expect(response).to redirect_to(sufia.edit_admin_admin_set_path(admin_set, anchor: 'participants'))
        expect(flash[:notice]).to eq 'Permissions updated'
      end
    end
  end
end
