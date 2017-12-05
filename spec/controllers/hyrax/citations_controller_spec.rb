RSpec.describe Hyrax::CitationsController do
  describe "#work" do
    let(:user) { create(:user) }
    let(:work) { create_for_repository(:work, user: user) }

    context "with an authenticated_user" do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
        create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(response).to render_template('layouts/hyrax/1_column')
        expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
      end
    end

    context "with an unauthenticated user" do
      it "is not successful" do
        get :work, params: { id: work }
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
        expect(flash[:alert]).to eq "You are not authorized to access this page."
        expect(session['user_return_to']).to eq request.url
      end
    end
  end
  describe "#file" do
    let(:user) { create(:user) }
    let(:file_set) { create_for_repository(:file_set, user: user) }

    context "with an authenticated_user" do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
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
