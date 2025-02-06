# frozen_string_literal: true
RSpec.describe Hyrax::Admin::WorkflowRolesController do
  describe '#index' do
    context "when you have permission" do
      before do
        allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Workflow Roles', admin_workflow_roles_path(locale: 'en'))
        get :index
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Hyrax::Admin::WorkflowRolesPresenter
        expect(response).to render_template('hyrax/dashboard')
      end
    end

    context "when they don't have permission" do
      it "throws a CanCan error" do
        get :index
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
      end
    end
  end

  describe '#create' do
    context 'when you have permission' do
      let(:form) { instance_double(Hyrax::Forms::WorkflowResponsibilityForm, save!: true) }

      before do
        allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
        allow(controller).to receive(:authorize!).and_return(true)
        allow(Hyrax::Forms::WorkflowResponsibilityForm).to receive(:new).and_return(form)
      end

      it 'is successful' do
        post :create, params: { sipity_workflow_responsibility: {} }
        expect(controller).to have_received(:authorize!).with(:create, Sipity::WorkflowResponsibility)
        expect(form).to have_received(:save!)
        expect(response).to redirect_to admin_workflow_roles_path
      end
    end

    context "when they don't have permission" do
      it 'throws a CanCan error' do
        post :create, params: { sipity_workflow_responsibility: {} }
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
      end
    end
  end

  describe '#destroy' do
    context "when you have permission" do
      let(:responsibility) { mock_model(Sipity::WorkflowResponsibility) }

      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(Sipity::WorkflowResponsibility).to receive(:find).with('1').and_return(responsibility)
      end

      it "is successful" do
        delete :destroy, params: { id: 1 }
        expect(controller).to have_received(:authorize!).with(:destroy, responsibility)
        expect(response).to redirect_to admin_workflow_roles_path
      end
    end

    context "when they don't have permission" do
      it "throws a CanCan error" do
        get :index
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
      end
    end
  end
end
