# frozen_string_literal: true
RSpec.describe Hyrax::Admin::UsersController, type: :controller do
  before do
    expect(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
  end

  describe "#index" do
    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.users.index.title'), admin_users_path)

      get :index
      expect(response).to be_successful
      expect(assigns[:presenter]).to be_kind_of Hyrax::Admin::UsersPresenter
    end
  end
end
