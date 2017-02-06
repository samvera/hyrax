require 'spec_helper'

# This tests the CurationConcerns::CurationConcernController module
# which is included into .internal_test_app/app/controllers/generic_works_controller.rb
describe CurationConcerns::GenericWorksController do
  let(:user) { create(:user) }
  let(:work) { create(:generic_work, user: user) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
  end
  before do
    sign_in user
  end

  describe 'integration test for suppressed documents' do
    let(:work) do
      create(:work, :public, state: Vocab::FedoraResourceStatus.inactive)
    end
    it 'renders the unavailable message because it is in workflow' do
      get :show, params: { id: work }
      expect(response.code).to eq '401'
      expect(response).to render_template(:unavailable)
      expect(assigns[:presenter]).to be_instance_of CurationConcerns::WorkShowPresenter
      expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
    end
  end

  describe '#show' do
    context 'my own private work' do
      let(:work) { create(:private_generic_work, user: user) }
      it 'shows me the page' do
        get :show, params: { id: work }
        expect(response).to be_success
      end

      context "with a parent work" do
        let(:parent) { create(:generic_work, title: ['Parent Work'], user: user, ordered_members: [work]) }
        let!(:parent_sipity_entity) do
          create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
        end
        it "sets the parent presenter" do
          get :show, params: { id: work, parent_id: parent }
          expect(response).to be_success
          expect(assigns[:parent_presenter]).to be_instance_of CurationConcerns::WorkShowPresenter
        end
      end
    end

    context 'someone elses private work' do
      let(:work) { create(:private_generic_work) }
      it 'shows unauthorized message' do
        get :show, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:work) { create(:public_generic_work) }
      context "html" do
        it 'shows me the page' do
          expect(controller). to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
          get :show, params: { id: work }
          expect(response).to be_success
        end
      end

      context "ttl" do
        let(:presenter) { double }
        before do
          allow(controller).to receive(:presenter).and_return(presenter)
          allow(presenter).to receive(:export_as_ttl).and_return("ttl graph")
        end

        it 'renders a turtle file' do
          get :show, params: { id: '99999999', format: :ttl }
          expect(response).to be_successful
          expect(response.body).to eq "ttl graph"
          expect(response.content_type).to eq 'text/turtle'
        end
      end
    end

    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:work) { create(:private_generic_work) }
      it 'someone elses private work should show me the page' do
        get :show, params: { id: work }
        expect(response).to be_success
      end
    end

    context 'with work still in workflow' do
      before do
        allow(controller).to receive(:search_results).and_return([nil, document_list])
      end
      context 'with a user lacking workflow permission' do
        before do
          allow(SolrDocument).to receive(:find).and_return(document)
        end
        let(:document_list) { [] }
        let(:document) { instance_double(SolrDocument, suppressed?: true) }
        it 'shows the unauthorized message' do
          get :show, params: { id: '99999' }
          expect(response.code).to eq '401'
          expect(response).to render_template(:unavailable)
          expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
        end
      end
      context 'with a user granted workflow permission' do
        let(:document_list) { [document] }
        let(:document) { instance_double(SolrDocument) }
        it 'renders without the unauthorized message' do
          get :show, params: { id: '88888' }
          expect(response.code).to eq '200'
          expect(response).to render_template(:show)
          expect(flash[:notice]).to be_nil
        end
      end
    end

    context 'when a ObjectNotFoundError is raised' do
      it 'returns 404 page' do
        allow(controller).to receive(:show).and_raise(ActiveFedora::ObjectNotFoundError)
        expect(controller).to receive(:render_404) { controller.render body: nil }
        get :show, params: { id: 'abc123' }
      end
    end
  end

  describe '#new' do
    context 'my work' do
      it 'shows me the page' do
        get :new
        expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
        expect(response).to be_success
      end
    end
  end

  describe '#create' do
    let(:actor) { double(create: create_status) }
    before do
      allow(CurationConcerns::CurationConcern).to receive(:actor).and_return(actor)
    end
    let(:create_status) { true }

    context 'when create is successful' do
      let(:work) { stub_model(GenericWork) }
      it 'creates a work' do
        allow(controller).to receive(:curation_concern).and_return(work)
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
      end
    end

    context 'when create fails' do
      let(:create_status) { false }
      it 'draws the form again' do
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response.status).to eq 422
        expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
        expect(response).to render_template 'new'
      end
    end

    context 'when not authorized' do
      before { allow(controller.current_ability).to receive(:can?).and_return(false) }

      it 'shows the unauthorized message' do
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end
  end

  describe '#edit' do
    context 'my own private work' do
      let(:work) { create(:private_generic_work, user: user) }
      it 'shows me the page' do
        get :edit, params: { id: work }
        expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
        expect(response).to be_success
      end
    end

    context 'someone elses private work' do
      routes { Rails.application.class.routes }
      let(:work) { create(:private_generic_work) }
      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:work) { create(:public_generic_work) }
      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:work) { create(:private_generic_work) }
      it 'someone elses private work should show me the page' do
        get :edit, params: { id: work }
        expect(response).to be_success
      end
    end
  end

  describe '#update' do
    let(:work) { create(:private_generic_work, user: user) }
    let(:visibility_changed) { false }
    let(:actor) { double(update: true) }
    before do
      allow(CurationConcerns::CurationConcern).to receive(:actor).and_return(actor)
      allow_any_instance_of(GenericWork).to receive(:visibility_changed?).and_return(visibility_changed)
    end

    it 'updates the work' do
      patch :update, params: { id: work, generic_work: {} }
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
    end

    it "can update file membership" do
      patch :update, params: { id: work, generic_work: { ordered_member_ids: ['foo_123'] } }
      expected_params = { ordered_member_ids: ['foo_123'] }
      if Rails.version < '5.0.0'
        expect(actor).to have_received(:update).with(expected_params)
      else
        expect(actor).to have_received(:update).with(ActionController::Parameters.new(expected_params).permit!)
      end
    end

    describe 'changing rights' do
      let(:visibility_changed) { true }
      let(:actor) { double(update: true) }

      context 'when there are children' do
        let(:work) { create(:work_with_one_file, user: user) }
        it 'prompts to change the files access' do
          patch :update, params: { id: work, generic_work: {} }
          expect(response).to redirect_to main_app.confirm_curation_concerns_permission_path(controller.curation_concern)
        end
      end

      context 'without children' do
        it "doesn't prompt to change the files access" do
          patch :update, params: { id: work, generic_work: {} }
          expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
        end
      end
    end

    describe 'failure' do
      let(:actor) { double(update: false) }

      it 'renders the form' do
        patch :update, params: { id: work, generic_work: {} }
        expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
        expect(response).to render_template('edit')
      end
    end

    context 'someone elses public work' do
      let(:work) { create(:public_generic_work) }
      it 'shows the unauthorized message' do
        get :update, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:work) { create(:private_generic_work) }
      it 'someone elses private work should update the work' do
        patch :update, params: { id: work, generic_work: {} }
        expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
      end
    end
  end

  describe '#destroy' do
    let(:work) { create(:private_generic_work, user: user) }
    let(:parent_collection) { create(:collection) }

    it 'deletes the work' do
      delete :destroy, params: { id: work }
      expect(response).to redirect_to main_app.search_catalog_path
      expect(GenericWork).not_to exist(work.id)
    end

    context "when work is a member of a collection" do
      before do
        parent_collection.members = [work]
        parent_collection.save!
      end
      it 'deletes the work and updates the parent collection' do
        delete :destroy, params: { id: work }
        expect(GenericWork).not_to exist(work.id)
        expect(response).to redirect_to main_app.search_catalog_path
        expect(parent_collection.reload.members).to eq []
      end
    end

    it "invokes the after_destroy callback" do
      expect(CurationConcerns.config.callback).to receive(:run)
        .with(:after_destroy, work.id, user)
      delete :destroy, params: { id: work }
    end

    context 'someone elses public work' do
      let(:work) { create(:private_generic_work) }
      it 'shows unauthorized message' do
        delete :destroy, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      let(:work) { create(:private_generic_work) }
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it 'someone elses private work should delete the work' do
        delete :destroy, params: { id: work }
        expect(GenericWork).not_to exist(work.id)
      end
    end
  end

  describe '#file_manager' do
    let(:work) { create(:private_generic_work, user: user) }

    it "is successful" do
      get :file_manager, params: { id: work.id }
      expect(response).to be_success
      expect(assigns(:form)).not_to be_blank
    end
  end

  describe '#inspect_work' do
    let(:work) { create(:private_generic_work, user: user) }
    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it "the response is successful" do
        get :inspect_work, params: { id: work.id }
        expect(response).to be_success
        expect(assigns(:presenter)).not_to be_blank
      end
    end
  end
end
