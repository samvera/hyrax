# frozen_string_literal: true
RSpec.describe Hyrax::CitationsController do
  describe "#work" do
    let(:user) { create(:user) }
    let(:work) { valkyrie_create(:monograph, depositor: user.user_key, edit_users: [user]) }

    context "with an authenticated_user" do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
        create(:sipity_entity, proxy_for: work)
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(response).to render_template('layouts/hyrax/1_column')
        expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
      end
    end

    context "with an unauthenticated user" do
      let(:second_user) { FactoryBot.create(:user) }

      before do
        sign_in second_user
      end

      it "redirects to the home page" do
        get :work, params: { id: work }
        expect(response).to redirect_to main_app.root_path(locale: 'en')
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end

    context "when a user is not logged in" do
      it "redirects to the user login page" do
        get :work, params: { id: work }
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
        expect(flash[:alert]).to eq "You are not authorized to access this page."
        expect(session['user_return_to']).to eq request.url
      end
    end

    context "with a Valkyrie resource" do
      let(:work) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }
      before do
        sign_in user
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(response).to render_template('layouts/hyrax/1_column')
        expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
      end
    end
  end
  describe "#file" do
    let(:user) { create(:user) }
    let(:file_set) { valkyrie_create(:hyrax_file_set, edit_users: [user]) }

    context "with an authenticated_user" do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :file, params: { id: file_set }
        expect(response).to be_successful
        expect(response).to render_template('layouts/hyrax/1_column')
        expect(assigns(:presenter)).to be_kind_of Hyrax::FileSetPresenter
      end
    end

    context "with an unauthenticated user" do
      it "is not successful" do
        get :file, params: { id: file_set }
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
        expect(flash[:alert]).to eq "You are not authorized to access this page."
        expect(session['user_return_to']).to eq request.url
      end
    end
  end
end
