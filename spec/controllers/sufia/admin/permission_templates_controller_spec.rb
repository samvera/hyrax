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

  let(:form) { instance_double(Sufia::Forms::PermissionTemplateForm) }
  before do
    allow(Sufia::Forms::PermissionTemplateForm).to receive(:new).with(permission_template).and_return(form)
  end

  context "when signed in as an admin" do
    describe "update participants" do
      let(:admin_set) { create(:admin_set) }
      let!(:permission_template) { Sufia::PermissionTemplate.create!(admin_set_id: admin_set.id) }
      let(:grant_attributes) { [{ "agent_type" => "user", "agent_id" => "bob", "access" => "view" }] }
      let(:input_params) do
        { admin_set_id: admin_set.id,
          sufia_permission_template: form_attributes }
      end
      let(:form_attributes) { { visibility: 'open', access_grants_attributes: grant_attributes } }

      it "is successful" do
        expect(controller).to receive(:authorize!).with(:update, permission_template)
        expect(form).to receive(:update).with(ActionController::Parameters.new(form_attributes).permit!)
        put :update, params: input_params
        expect(response).to redirect_to(sufia.edit_admin_admin_set_path(admin_set, anchor: 'participants'))
        expect(flash[:notice]).to eq 'Permissions updated'
      end
    end
  end
end
