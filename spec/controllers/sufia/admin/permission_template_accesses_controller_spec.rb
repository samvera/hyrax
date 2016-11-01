require 'spec_helper'

RSpec.describe Sufia::Admin::PermissionTemplateAccessesController do
  routes { Sufia::Engine.routes }
  before do
    sign_in create(:user)
  end
  let(:sufia) { Sufia::Engine.routes.url_helpers }
  let(:permission_template_access) { create(:permission_template_access) }
  let(:admin_set_id) { permission_template_access.permission_template.admin_set_id }

  context "without admin privleges" do
    describe "destroy" do
      it "is unauthorized" do
        delete :destroy, params: { id: permission_template_access }
        expect(response).to be_unauthorized
      end
    end
  end

  context "when signed in as an admin" do
    describe "update" do
      it "is successful" do
        expect(controller).to receive(:authorize!).with(:destroy, permission_template_access)
        expect do
          delete :destroy, params: { id: permission_template_access }
        end.to change { Sufia::PermissionTemplateAccess.count }.by(-1)
        expect(response).to redirect_to(sufia.edit_admin_admin_set_path(admin_set_id, anchor: 'participants'))
        expect(flash[:notice]).to eq 'Permissions updated'
      end
    end
  end
end
