require 'spec_helper'

RSpec.describe Hyrax::Admin::PermissionTemplateAccessesController do
  routes { Hyrax::Engine.routes }
  before do
    sign_in create(:user)
  end
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:permission_template_access) { create(:permission_template_access) }
  let(:admin_set_id) { permission_template_access.permission_template.admin_set_id }

  context "without admin privleges" do
    describe "destroy" do
      before do
        allow(controller.current_ability).to receive(:test_edit).with(admin_set_id).and_return(false)
      end
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
        end.to change { Hyrax::PermissionTemplateAccess.count }.by(-1)
        expect(response).to redirect_to(hyrax.edit_admin_admin_set_path(admin_set_id, locale: 'en', anchor: 'participants'))
        expect(flash[:notice]).to eq(I18n.t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices'))
      end
    end
  end
end
