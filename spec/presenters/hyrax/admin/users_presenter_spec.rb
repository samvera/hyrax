RSpec.describe Hyrax::Admin::UsersPresenter do
  let(:instance) { described_class.new }
  let!(:user) { FactoryBot.create(:user) }
  let!(:admin_user) { FactoryBot.create(:user, groups: 'admin') }
  let!(:audit_user) { User.audit_user }
  let!(:batch_user) { User.batch_user }

  describe "#users" do
    it "includes all users except batch and audit users" do
      expect(instance.users).to match_array [admin_user, user]
    end
  end

  describe "#user_count" do
    it "counts users excluding batch_user and audit_user" do
      expect(instance.user_count).to eq 2
    end
  end

  describe "#user_roles" do
    describe "for an admin user" do
      it "finds the admin role" do
        expect(instance.user_roles(admin_user)).to eq(['admin'])
      end
    end
    describe "for a generic user with no user roles" do
      it "returns blank" do
        expect(instance.user_roles(user)).to eq([])
      end
    end
  end
end
