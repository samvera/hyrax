require 'spec_helper'

describe Sufia::Admin::AdminSetsController do
  let(:user) { create(:user) }

  context "a non admin" do
    describe "#index" do
      it 'is unauthorized' do
        get :index
        expect(response).to be_redirect
      end
    end

    describe "#new" do
      let!(:admin_set) { create(:admin_set) }

      it 'is unauthorized' do
        get :new
        expect(response).to be_redirect
      end
    end
  end

  context "as an admin" do
    before do
      sign_in user
      allow(controller).to receive(:authorize!).and_return(true)
    end

    describe "#index" do
      it 'allows an authorized user to view the page' do
        get :index
        expect(response).to be_success
        expect(assigns[:admin_sets]).to be_kind_of Array
      end
    end

    describe "#new" do
      it 'allows an authorized user to view the page' do
        get :new
        expect(response).to be_success
      end
    end

    describe "#create" do
      let(:service) { instance_double(Sufia::AdminSetService) }
      before do
        allow(Sufia::AdminSetService).to receive(:new)
          .with(AdminSet, user)
          .and_return(service)
      end

      context "when it's successful" do
        it 'creates file sets' do
          expect(service).to receive(:create).and_return(true)
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description' } }
          expect(response).to be_redirect
        end
      end

      context "when it fails" do
        it 'shows the new form' do
          expect(service).to receive(:create).and_return(false)
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description' } }
          expect(response).to render_template 'new'
        end
      end
    end
  end
end
