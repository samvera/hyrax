RSpec.describe Hyrax::Admin::PermissionTemplateAccessesController do
  routes { Hyrax::Engine.routes }
  before do
    sign_in create(:user)
  end
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:permission_template_access) { create(:permission_template_access) }
  let(:admin_set_id) { permission_template_access.permission_template.admin_set_id }

  describe "destroy" do
    context "without admin privleges" do
      before do
        allow(controller.current_ability).to receive(:test_edit).with(admin_set_id).and_return(false)
      end
      it "is unauthorized" do
        delete :destroy, params: { id: permission_template_access }
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as an admin" do
      let(:permission_template_access) do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: agent_type,
               agent_id: agent_id)
      end
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
      let(:admin_set) { create(:admin_set, edit_users: ['Liz']) }

      context 'when deleting the admin users group' do
        let(:agent_type) { 'group' }
        let(:agent_id) { 'admin' }

        it "is successful" do
          expect(controller).to receive(:authorize!).with(:destroy, permission_template_access)
          expect do
            delete :destroy, params: { id: permission_template_access }
          end.to change { Hyrax::PermissionTemplateAccess.count(-1) }
          expect(response).to redirect_to(hyrax.edit_admin_admin_set_path(admin_set_id, locale: 'en', anchor: 'participants'))
          expect(flash[:notice]).to eq I18n.t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
          expect(admin_set.reload.edit_users).to be_empty
        end
      end
      context 'with deleting any agent other than the admin users group' do
        let(:agent_type) { 'user' }
        let(:agent_id) { 'Liz' }

        it "is successful" do
          expect(controller).to receive(:authorize!).with(:destroy, permission_template_access)
          expect do
            delete :destroy, params: { id: permission_template_access }
          end.to change { Hyrax::PermissionTemplateAccess.count }.by(-1)
          expect(response).to redirect_to(hyrax.edit_admin_admin_set_path(admin_set_id, locale: 'en', anchor: 'participants'))
          expect(flash[:notice]).to eq(I18n.t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices'))
          expect(admin_set.reload.edit_users).to be_empty
        end
      end
    end
  end
end
