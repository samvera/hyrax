describe CitationsController do
  let(:user) { create(:user) }

  describe "#work" do
    let(:work) { create(:work, user: user) }
    before do
      sign_in user
      request.env['HTTP_REFERER'] = 'http://test.host/foo'
    end

    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
      get :work, id: work
      expect(response).to be_successful
      expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
    end
  end
end
