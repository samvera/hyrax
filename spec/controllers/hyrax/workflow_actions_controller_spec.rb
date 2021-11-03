# frozen_string_literal: true
RSpec.describe Hyrax::WorkflowActionsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:monograph) }
  let(:form) { instance_double(described_class::DEFAULT_FORM_CLASS, errors: {}) }

  routes { Rails.application.routes }

  before do
    allow(described_class::DEFAULT_FORM_CLASS).to receive(:new).and_return(form)
  end

  describe '#update' do
    it 'will redirect to login path if user not authenticated' do
      put :update, params: { id: work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.user_session_path)
    end

    it 'will render :unauthorized when action is not valid for the given user' do
      expect(form).to receive(:save).and_return(false)
      sign_in(user)

      put :update, params: { id: work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to be_unauthorized
    end

    it 'will redirect when the form is successfully save' do
      expect(form).to receive(:save).and_return(true)
      sign_in(user)

      put :update, params: { id: work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.hyrax_monograph_path(work, locale: 'en'))
    end

    context 'when responding to json' do
      it 'will render :ok when the form is successfully saved' do
        expect(form).to receive(:save).and_return(true)
        sign_in(user)

        put :update, params: { id: work.to_param, workflow_action: { name: 'advance', comment: '' } }, format: :json
        expect(response.status).to eq 200
      end

      it 'will render :unprocessable_entity when the form fails to save' do
        expect(form).to receive(:save).and_return(false)
        sign_in(user)

        put :update, params: { id: work.to_param, workflow_action: { name: 'advance', comment: '' } }, format: :json
        expect(response.status).to eq 422
      end
    end
  end
end
