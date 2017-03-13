describe Hyrax::Admin::UsersController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  before do
    expect(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
  end
  let!(:admin_user) { FactoryGirl.create(:user, groups: 'admin') }
  let!(:audit_user) { User.audit_user }
  let!(:batch_user) { User.batch_user }
  let!(:guest_user) { FactoryGirl.create(:user, :guest) }

  describe "#index" do
    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.toolbar.admin.menu'), admin_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.users.index.title'), admin_users_path)

      get :index
      expect(response).to be_successful
    end

    it "excludes audit_user, batch_user, and guest user" do
      get :index
      expect(assigns[:presenter].users.to_a).to match_array [user, admin_user]
      expect(response).to be_successful
    end
  end
end
