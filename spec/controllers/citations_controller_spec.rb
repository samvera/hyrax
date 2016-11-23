describe CitationsController do
  describe "#work" do
    let(:user) { create(:user) }
    let(:work) { create(:work, user: user) }

    context "with an authenticated_user" do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :work, params: { id: work }
        expect(response).to be_successful
        expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
      end
    end

    context "with an unauthenticated user" do
      it "is not successful" do
        get :work, params: { id: work }
        expect(response).to redirect_to main_app.new_user_session_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
        expect(session['user_return_to']).to eq request.url
      end
    end
  end
  describe "#file" do
    let(:user) { create(:user) }
    let(:file_set) { create(:file_set, user: user) }

    context "with an authenticated_user" do
      before do
        sign_in user
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      # TODO: fix this behavior
      it "is not successful" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :file, params: { id: file_set }
        expect(response).not_to be_successful
        # expect(assigns(:presenter)).to be_kind_of Sufia::FileSetPresenter
      end
    end

    context "with an unauthenticated user" do
      it "is not successful" do
        get :file, params: { id: file_set }
        expect(response).to redirect_to main_app.new_user_session_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
        expect(session['user_return_to']).to eq request.url
      end
    end
  end
end
