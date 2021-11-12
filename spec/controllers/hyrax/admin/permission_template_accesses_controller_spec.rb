# frozen_string_literal: true
RSpec.describe Hyrax::Admin::PermissionTemplateAccessesController do
  routes { Hyrax::Engine.routes }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:permission_template_access) { FactoryBot.create(:permission_template_access) }
  let(:source_id) { permission_template_access.permission_template.source_id }

  before { sign_in FactoryBot.create(:user) }

  describe "destroy" do
    context "without admin privleges" do
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
      let(:permission_template_access) do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: agent_type,
               agent_id: agent_id)
      end

      it 'can remove admin group from depositors'
      it 'can remove admin group from viewers'

      context 'when source is an admin set' do
        let(:admin_set) { FactoryBot.create(:admin_set, edit_users: ['Liz']) }

        let(:permission_template) do
          FactoryBot.create(:permission_template, source_id: admin_set.id)
        end

        context 'when deleting the admin users group' do
          let(:agent_type) { 'group' }
          let(:agent_id) { 'admin' }

          before do
            allow(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access)
          end

          it "does not delete the permission template access" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .not_to change { Hyrax::PermissionTemplateAccess.count }
          end

          it "does something" do
            delete :destroy, params: { id: permission_template_access }

            expect(response)
              .to redirect_to(hyrax.edit_admin_admin_set_path(source_id,
                                                              locale: 'en',
                                                              anchor: 'participants'))
          end

          it "does not flash a notice" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:notice]).not_to be_present
          end

          it "flashes an alert for failure" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:alert]).to eq 'The repository administrators group cannot be removed'
          end
        end

        context 'with deleting any agent other than the admin users group' do
          let(:agent_type) { 'user' }
          let(:agent_id) { 'Liz' }

          before do
            allow(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access)
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

            expect(flash[:notice])
              .to eq "The administrative set's participant rights have been updated"
          end

          it "empties the admin set's edit users" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .to change { admin_set.reload.edit_users.to_a }
              .to be_empty
          end
        end
      end

      context 'when source is a collection' do
        let(:permission_template) { create(:permission_template, source_id: collection.id) }
        let(:collection) { create(:collection, edit_users: ['Liz']) }

        context 'when deleting the admin users group' do
          let(:agent_type) { 'group' }
          let(:agent_id) { 'admin' }

          before do
            allow(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access)
          end

          it "does not delete the permission template access" do
            expect { delete :destroy, params: { id: permission_template_access } }
              .not_to change { Hyrax::PermissionTemplateAccess.count }
          end

          it "redirects to the dashboard collection edit path" do
            delete :destroy, params: { id: permission_template_access }

            expect(response)
              .to redirect_to(hyrax.edit_dashboard_collection_path(source_id,
                                                                   locale: 'en',
                                                                   anchor: 'sharing'))
          end

          it "does not flash a notice" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:notice]).not_to be_present
          end

          it "flashes an alert showing failure status" do
            delete :destroy, params: { id: permission_template_access }

            expect(flash[:alert])
              .to eq 'The repository administrators group cannot be removed'
          end
        end

        context 'as an agent not in the admin users group' do
          let(:agent_type) { 'user' }
          let(:agent_id) { 'Liz' }

          before do
            allow(controller)
              .to receive(:authorize!)
              .with(:destroy, permission_template_access)
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

            expect(flash[:notice])
              .to eq "The collection's sharing options have been updated."
          end
        end
      end
    end
  end
end
