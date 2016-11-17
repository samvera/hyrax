require 'spec_helper'

feature 'admin dashboard' do
  let(:user) { FactoryGirl.create(:user) }
  context "when given permission" do
    before do
      allow_any_instance_of(CurationConcerns::AdminController).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    end
    it "loads the sidebar" do
      visit "/admin"
      expect(page).to have_link "Admin Dashboard"
    end
  end
end
