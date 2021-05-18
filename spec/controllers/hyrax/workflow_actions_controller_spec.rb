# frozen_string_literal: true
RSpec.describe Hyrax::WorkflowActionsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:generic_work) { FactoryBot.create(:work) }
  let(:form) { instance_double(described_class::DEFAULT_FORM_CLASS) }

  routes { Rails.application.routes }

  before do
    allow(described_class::DEFAULT_FORM_CLASS).to receive(:new).and_return(form)
  end

  describe '#update' do
    context "with a valkyrie object" do
      let(:generic_work) { FactoryBot.valkyrie_create(:monograph) }
      let(:admin_set) { FactoryBot.create(:admin_set, with_permission_template: true) }
      let(:permission_template) { Hyrax::PermissionTemplate.find_by!(source_id: admin_set.id.to_s) }
      it 'will redirect to login path if user not authenticated' do
        put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
        expect(response).to redirect_to(main_app.user_session_path)
      end

      it 'will render :unauthorized when action is not valid for the given user' do
        expect(form).to receive(:save).and_return(false)
        sign_in(user)

        put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
        expect(response).to be_unauthorized
      end

      it 'will redirect when the form is successfully save' do
        expect(form).to receive(:save).and_return(true)
        sign_in(user)

        put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
        expect(response).to redirect_to(main_app.hyrax_monograph_path(generic_work, locale: 'en'))
      end
    end
    context 'when responding to json' do
      it 'will render :ok when the form is successfully saved' do
        expect(form).to receive(:save).and_return(true)
        sign_in(user)

        put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }, format: :json
        expect(response.status).to eq 200
      end

      it 'will render :unprocessable_entity when the form fails to save' do
        expect(form).to receive(:save).and_return(false)
        sign_in(user)

        put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }, format: :json
        expect(response.status).to eq 422
      end
    end
  end
end
