require 'spec_helper'

RSpec.describe CurationConcerns::WorkflowActionsController, type: :controller do
  # routes { Rails.application.class.routes }
  let(:user) { FactoryGirl.create(:user) }
  let(:generic_work) { GenericWork.new(id: '123') }
  before do
    allow(ActiveFedora::Base).to receive(:find).with(generic_work.to_param).and_return(generic_work)
    allow(generic_work).to receive(:persisted?).and_return(true)
  end
  describe '#update' do
    it 'will redirect to login path if user not authenticated' do
      put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.user_session_path)
    end
    it 'will render :unauthorized when action is not valid for the given user' do
      expect(CurationConcerns::Forms::WorkflowActionForm).to receive(:save).and_return(false)
      sign_in(user)

      put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to be_unauthorized
    end
    it 'will redirect when the form is successfully save' do
      expect(CurationConcerns::Forms::WorkflowActionForm).to receive(:save).and_return(true)
      sign_in(user)

      put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.curation_concerns_generic_work_path(generic_work))
    end
  end
end
