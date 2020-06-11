# frozen_string_literal: true
RSpec.describe Hyrax::Admin::PermissionTemplateAccessesController do
  routes { Hyrax::Engine.routes }
  before do
    sign_in create(:user)
  end
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:permission_template_access) { create(:permission_template_access) }
  let(:source_id) { permission_template_access.permission_template.source_id }

  describe "destroy" do
    context "without admin privleges" do
      before do
        allow(controller.current_ability).to receive(:test_edit).with(source_id).and_return(false)
      end
      it "is unauthorized" do
        delete :destroy, params: { id: permission_template_access }
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as an admin" do
      # TODO: Need test that shows delete of admin group form depositors and viewers is allowed
      let(:permission_template_access) do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: agent_type,
               agent_id: agent_id)
      end

      context 'when source is an admin set' do
        let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
        let(:admin_set) { create(:admin_set, edit_users: ['Liz']) }

        context 'when deleting the admin users group' do
          let(:agent_type) { 'group' }
          let(:agent_id) { 'admin' }

          it "is fails" do
            expect(controller).to receive(:authorize!).with(:destroy, permission_template_access)
            expect do
              delete :destroy, params: { id: permission_template_access }
            end.not_to change { Hyrax::PermissionTemplateAccess.count }
            expect(response).to redirect_to(hyrax.edit_admin_admin_set_path(source_id, locale: 'en', anchor: 'participants'))
            expect(flash[:notice]).not_to eq I18n.t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
            expect(flash[:alert]).to eq 'The repository administrators group cannot be removed'
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
            expect(response).to redirect_to(hyrax.edit_admin_admin_set_path(source_id, locale: 'en', anchor: 'participants'))
            expect(flash[:notice]).to eq(I18n.t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices'))
            expect(admin_set.reload.edit_users).to be_empty
          end
        end
      end

      context 'when source is a collection' do
        let(:permission_template) { create(:permission_template, source_id: collection.id) }
        let(:collection) { create(:collection, edit_users: ['Liz']) }

        context 'when deleting the admin users group' do
          let(:agent_type) { 'group' }
          let(:agent_id) { 'admin' }

          it "fails" do
            expect(controller).to receive(:authorize!).with(:destroy, permission_template_access)
            expect do
              delete :destroy, params: { id: permission_template_access }
            end.not_to change { Hyrax::PermissionTemplateAccess.count }
            expect(response).to redirect_to(hyrax.edit_dashboard_collection_path(source_id, locale: 'en', anchor: 'sharing'))
            expect(flash[:notice]).not_to eq I18n.t('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices')
            expect(flash[:alert]).to eq 'The repository administrators group cannot be removed'
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
            expect(response).to redirect_to(hyrax.edit_dashboard_collection_path(source_id, locale: 'en', anchor: 'sharing'))
            expect(flash[:notice]).to eq(I18n.t('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices'))
          end
        end
      end
    end
  end
end
