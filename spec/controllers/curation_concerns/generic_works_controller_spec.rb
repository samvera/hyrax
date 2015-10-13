require 'spec_helper'

# This tests the CurationConcerns::CurationConcernController module
# which is included into spec/internal/app/controllers/generic_works_controller.rb
describe CurationConcerns::GenericWorksController do
  let(:user) { create(:user) }
  before { sign_in user }

  describe '#show' do
    context 'my own private work' do
      let(:a_work) { create(:private_generic_work, user: user) }
      it 'shows me the page' do
        get :show, id: a_work
        expect(response).to be_success
      end
    end

    context 'someone elses private work' do
      let(:a_work) { create(:private_generic_work) }
      it 'shows unauthorized message' do
        get :show, id: a_work
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:a_work) { create(:public_generic_work) }
      it 'shows me the page' do
        get :show, id: a_work
        expect(response).to be_success
      end
    end

    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:a_work) { create(:private_generic_work) }
      it 'someone elses private work should show me the page' do
        get :show, id: a_work
        expect(response).to be_success
      end
    end
  end

  describe '#new' do
    context 'my work' do
      it 'shows me the page' do
        get :new
        expect(response).to be_success
      end
    end
  end

  describe '#create' do
    it 'creates a work' do
      expect do
        post :create, generic_work: { title: ['a title'] }
      end.to change { GenericWork.count }.by(1)
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(assigns[:curation_concern])
    end
  end

  describe '#edit' do
    context 'my own private work' do
      let(:a_work) { create(:private_generic_work, user: user) }
      it 'shows me the page' do
        get :edit, id: a_work
        expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
        expect(response).to be_success
      end
    end

    context 'someone elses private work' do
      routes { Rails.application.class.routes }
      let(:a_work) { create(:private_generic_work) }
      it 'shows the unauthorized message' do
        get :edit, id: a_work
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:a_work) { create(:public_generic_work) }
      it 'shows the unauthorized message' do
        get :edit, id: a_work
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:a_work) { create(:private_generic_work) }
      it 'someone elses private work should show me the page' do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end
  end

  describe '#update' do
    let(:a_work) { FactoryGirl.create(:private_generic_work, user: user) }
    before do
      allow(controller).to receive(:actor).and_return(actor)
    end
    let(:actor) { double(update: true, visibility_changed?: false) }

    it 'updates the work' do
      patch :update, id: a_work, generic_work: {}
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(a_work)
    end

    describe 'changing rights' do
      let(:actor) { double(update: true, visibility_changed?: true) }

      it 'prompts to change the files access' do
        patch :update, id: a_work
        expect(response).to redirect_to main_app.confirm_curation_concerns_permission_path(controller.curation_concern)
      end
    end

    describe 'failure' do
      let(:actor) { double(update: false, visibility_changed?: false) }

      it 'renders the form' do
        patch :update, id: a_work
        expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
        expect(response).to render_template('edit')
      end
    end

    context 'someone elses public work' do
      let(:a_work) { create(:public_generic_work) }
      it 'shows the unauthorized message' do
        get :update, id: a_work
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:a_work) { create(:private_generic_work) }
      it 'someone elses private work should update the work' do
        patch :update, id: a_work, generic_work: {}
        expect(response).to redirect_to main_app.curation_concerns_generic_work_path(a_work)
      end
    end
  end

  describe '#destroy' do
    let(:work_to_be_deleted) { create(:private_generic_work, user: user) }

    it 'deletes the work' do
      delete :destroy, id: work_to_be_deleted
      expect(response).to redirect_to main_app.catalog_index_path
      expect(GenericWork).not_to exist(work_to_be_deleted.id)
    end

    context 'someone elses public work' do
      let(:work_to_be_deleted) { create(:private_generic_work) }
      it 'shows unauthorized message' do
        delete :destroy, id: work_to_be_deleted
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      let(:work_to_be_deleted) { create(:private_generic_work) }
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it 'someone elses private work should delete the work' do
        delete :destroy, id: work_to_be_deleted
        expect(GenericWork).not_to exist(work_to_be_deleted.id)
      end
    end
  end
end
