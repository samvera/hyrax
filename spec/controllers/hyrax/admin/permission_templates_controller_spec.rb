# frozen_string_literal: true
RSpec.describe Hyrax::Admin::PermissionTemplatesController do
  routes { Hyrax::Engine.routes }
  before do
    sign_in create(:user)
    allow(Hyrax::Forms::PermissionTemplateForm).to receive(:new).with(permission_template).and_return(form)
  end
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:form) { instance_double(Hyrax::Forms::PermissionTemplateForm) }

  context "without admin privleges" do
    describe "update" do
      let(:permission_template) { create(:permission_template) }

      before do
        allow(controller.current_ability).to receive(:can?).with(:update, permission_template).and_return(false)
      end

      it "is unauthorized for admin sets" do
        # This spec was not firing as expected. It was getting a nil permission template. This mock expectation is a bit
        # odd, but it needs to go rather deep into CanCan to behave accordingly.
        put :update, params: { id: permission_template, admin_set_id: permission_template.source_id }
        expect(assigns(:permission_template)).to eq(permission_template)
        expect(response).to be_unauthorized
      end

      it "is unauthorized for collections" do
        # This spec was not firing as expected. It was getting a nil permission template. This mock expectation is a bit
        # odd, but it needs to go rather deep into CanCan to behave accordingly.
        put :update, params: { id: permission_template, collection_id: permission_template.source_id }
        expect(assigns(:permission_template)).to eq(permission_template)
        expect(response).to be_unauthorized
      end
    end
  end

  context "when signed in as an admin" do
    let!(:permission_template) { create(:permission_template) }
    let(:grant_attributes) { [{ "agent_type" => "user", "agent_id" => "bob", "access" => "view" }] }
    let(:form_attributes) { { visibility: 'open', access_grants_attributes: grant_attributes } }

    describe "update admin set participants" do
      let(:input_params) do
        { admin_set_id: permission_template.source_id,
          permission_template: form_attributes }
      end

      it "is successful" do
        expect(controller).to receive(:authorize!).with(:update, Hyrax::PermissionTemplate)
        expect(form).to receive(:update).with(ActionController::Parameters.new(form_attributes).permit!).and_return(updated: true, content_tab: 'participants')
        put :update, params: input_params
        expect(response).to redirect_to(hyrax.edit_admin_admin_set_path(permission_template.source_id, locale: 'en', anchor: 'participants'))
        expect(flash[:notice]).to eq(I18n.t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices'))
      end
    end

    describe "update collection participants" do
      let(:input_params) do
        { collection_id: permission_template.source_id,
          permission_template: form_attributes }
      end

      it "is successful" do
        expect(controller).to receive(:authorize!).with(:update, Hyrax::PermissionTemplate)
        expect(form).to receive(:update).with(ActionController::Parameters.new(form_attributes).permit!).and_return(updated: true, content_tab: 'sharing')
        put :update, params: input_params
        expect(response).to redirect_to(hyrax.edit_dashboard_collection_path(permission_template.source_id, locale: 'en', anchor: 'sharing'))
        expect(flash[:notice]).to eq(I18n.t('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices'))
      end

      context "with embargo date" do
        let(:release_date) { '2023-09-30' }

        before do
          permission_template.update(release_date: release_date)
        end

        it "is successful with embargo date intact" do
          expect(controller).to receive(:authorize!).with(:update, Hyrax::PermissionTemplate)
          expect(form).to receive(:update).with(ActionController::Parameters.new(form_attributes).permit!).and_return(updated: true, content_tab: 'sharing')
          put :update, params: input_params
          expect(response).to redirect_to(hyrax.edit_dashboard_collection_path(permission_template.source_id, locale: 'en', anchor: 'sharing'))

          updated = Hyrax::PermissionTemplate.find_by(id: permission_template.id)
          expect(updated.release_date.strftime('%Y-%m-%d')).to eq(release_date)
        end
      end
    end
  end
end
