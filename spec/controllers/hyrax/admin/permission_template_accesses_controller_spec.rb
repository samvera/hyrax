# frozen_string_literal: true
RSpec.describe Hyrax::Admin::PermissionTemplateAccessesController do
  routes { Hyrax::Engine.routes }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:permission_template_access) { FactoryBot.create(:permission_template_access) }
  let(:source_id) { permission_template_access.permission_template.source_id }
  let(:admin_set_update_notice) { 'The administrative set\'s participant rights have been updated' }
  let(:collection_update_notice) { 'The collection\'s sharing options have been updated.' }
  let(:rep_admin_cannot_remove_notice) { 'The repository administrators group cannot be removed' }

  before { sign_in FactoryBot.create(:user) }

  describe "destroy" do
    context "without admin privileges" do
      let(:user_liz) { FactoryBot.create(:user, email: 'liz@example.com') }
      before do
        allow(controller.current_ability)
          .to receive(:test_edit)
          .with(source_id)
          .and_return(false)
      end

      it "is unauthorized" do
        delete :destroy, params: { id: permission_template_access }

        expect(response).to be_unauthorized
      end
    end

    context "when signed in as an admin" do
      let(:user_liz) { FactoryBot.create(:admin, email: 'liz@example.com') }
      let(:permission_template_access) do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: agent_type,
               agent_id: agent_id)
      end
      let(:access_destroy) { true }

      it 'can remove admin group from depositors'
      it 'can remove admin group from viewers'

      context 'when source is an admin set' do
        let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, edit_users: [user_liz.user_key]) }

        let(:permission_template) do
          FactoryBot.create(:permission_template, source_id: admin_set.id)
        end

        context 'when deleting the admin users group' do
          let(:agent_type) { 'group' }
          let(:agent_id) { 'admin' }

          before do
            expect(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access).at_least(:once).and_return access_destroy
          end

          it "deletes the permission template access" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { Hyrax::PermissionTemplateAccess.count }
              .by(-1)
          end

          it "redirects to the admin dashboard's admin set edit path" do
            delete :destroy, params: { id: permission_template_access }

            expect(response)
              .to redirect_to(hyrax.edit_admin_admin_set_path(source_id,
                                                              locale: 'en',
                                                              anchor: 'participants'))
          end

          it "flashes a notice" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:notice]).to eq admin_set_update_notice
          end

          it "empties the admin set's edit users" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { Hyrax.query_service.find_by(id: admin_set.id).permission_manager.edit_users.to_a }
              .to be_empty
          end
        end

        context 'with deleting any agent other than the admin users group' do
          let(:agent_type) { 'user' }
          let(:agent_id) { user_liz.user_key }

          before do
            expect(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access).at_least(:once).and_return access_destroy
          end

          it "deletes the permission template access" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { Hyrax::PermissionTemplateAccess.count }
              .by(-1)
          end

          it "redirects to the admin dashboard's admin set edit path" do
            delete :destroy, params: { id: permission_template_access }

            expect(response)
              .to redirect_to(hyrax.edit_admin_admin_set_path(source_id,
                                                                   locale: 'en',
                                                                   anchor: 'participants'))
          end

          it "flashes a notice" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:notice]).to eq admin_set_update_notice
          end

          it "empties the admin set's edit users" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { Hyrax.query_service.find_by(id: admin_set.id).permission_manager.edit_users.to_a }
              .to be_empty
          end
        end
      end

      context 'when source is a collection' do
        let(:permission_template) { create(:permission_template, source_id: collection.id) }
        let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, edit_users: [user_liz.user_key], with_permission_template: false) }

        context 'when deleting the admin users group' do
          let(:agent_type) { 'group' }
          let(:agent_id) { 'admin' }

          before do
            expect(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access).at_least(:once).and_return access_destroy
          end

          it "deletes the permission template access" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { Hyrax::PermissionTemplateAccess.count }
              .by(-1)
          end

          it "redirects to the dashboard collection edit path" do
            delete :destroy, params: { id: permission_template_access }

            expect(response)
              .to redirect_to(hyrax.edit_dashboard_collection_path(source_id,
                                                                   locale: 'en',
                                                                   anchor: 'sharing'))
          end

          it "flashes a notice" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:notice]).to eq collection_update_notice
          end
        end

        context 'as an agent not in the admin users group' do
          let(:agent_type) { 'user' }
          let(:agent_id) { user_liz.user_key }

          before do
            expect(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access).at_least(:once).and_return access_destroy
          end

          it "deletes the permission template access" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { Hyrax::PermissionTemplateAccess.count }
              .by(-1)
          end

          it "redirects to the dashboard collection edit path" do
            delete :destroy, params: { id: permission_template_access }

            expect(response)
              .to redirect_to(hyrax.edit_dashboard_collection_path(source_id,
                                                                   locale: 'en',
                                                                   anchor: 'sharing'))
          end

          it "flashes a notice" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:notice]).to eq collection_update_notice
          end
        end
      end
    end
  end
end
