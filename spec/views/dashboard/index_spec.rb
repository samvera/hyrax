# coding: utf-8
require 'spec_helper'

describe "dashboard/index.html.erb", type: :view do
  before do
    @user = mock_model(User, name: "Charles Francis Xavier", user_key: "charles")
    allow(@user).to receive(:title).and_return("Professor, Head")
    allow(@user).to receive(:department).and_return("Xavier’s School for Gifted Youngsters")
    allow(@user).to receive(:telephone).and_return("814.865.8399")
    allow(@user).to receive(:email).and_return("chuck@xsgy.edu")
    allow(@user).to receive(:login).and_return("chuck")
    allow(@user).to receive(:all_following).and_return(["magneto"])
    allow(@user).to receive(:followers).and_return(["wolverine", "storm"])
    allow(@user).to receive(:can_receive_deposits_from).and_return([])
    allow(@user).to receive(:total_file_views).and_return(1)
    allow(@user).to receive(:total_file_downloads).and_return(3)
    allow(controller).to receive(:current_user).and_return(@user)
    @ability = instance_double("Ability")
    allow(controller).to receive(:current_ability).and_return(@ability)
    allow(@ability).to receive(:can?).with(:create, GenericFile).and_return(can_create_file)
    allow(@ability).to receive(:can?).with(:create, GenericWork).and_return(can_create_work)
    allow(@ability).to receive(:can?).with(:create, Collection).and_return(can_create_collection)
    allow(view).to receive(:number_of_files).and_return("15")
    allow(view).to receive(:number_of_collections).and_return("3")
    assign(:activity, [])
    assign(:notifications, [])
  end
  let(:can_create_file) { true }
  let(:can_create_work) { true }
  let(:can_create_collection) { true }

  describe "heading" do
    before do
      render
      @heading = view.content_for(:heading)
    end

    it "displays welcome message and links" do
      expect(@heading).to have_link("Create Work", sufia.new_generic_work_path)
      expect(@heading).to have_link("Create Collection", collections.new_collection_path)
      expect(@heading).to have_link("View Works", sufia.dashboard_files_path)
      expect(@heading).to have_link("Upload", sufia.new_generic_file_path)
      expect(@heading).to include "My Dashboard"
      expect(@heading).to include "Hello, Charles Francis Xavier"
    end

    context "when the user can't create works" do
      let(:can_create_work) { false }
      it "does not display the create work button" do
        expect(@heading).not_to have_link("Create Work", sufia.new_generic_work_path)
      end
    end
    context "when the user can't create collections" do
      let(:can_create_collection) { false }
      it "does not display the create collection button" do
        expect(@heading).not_to have_link("Create Collection", collections.new_collection_path)
      end
    end
    context "when the user can't create files" do
      let(:can_create_file) { false }
      it "does not display the upload button" do
        expect(@heading).not_to have_link("Upload", sufia.new_generic_file_path)
      end
    end
  end

  describe "sidebar" do
    before do
      render
      @sidebar = view.content_for(:sidebar)
    end

    it "displays information about the user" do
      expect(@sidebar).to include "Charles Francis Xavier"
      expect(@sidebar).to include "Professor, Head"
      expect(@sidebar).to include "Xavier’s School for Gifted Youngsters"
      expect(@sidebar).to include "814.865.8399"
      expect(@sidebar).to include "chuck@xsgy.edu"
    end

    it "has links to view and edit the user's profile" do
      expect(@sidebar).to include '<a class="btn btn-default" href="' + sufia.profile_path(@user) + '">View Profile</a>'
      expect(@sidebar).to include '<a class="btn btn-default" href="' + sufia.edit_profile_path(@user) + '">Edit Profile</a>'
    end

    it "displays user statistics" do
      expect(@sidebar).to include "Your Statistics"
      expect(@sidebar).to include '<span class="badge">1</span>'
      expect(@sidebar).to include '<span class="badge">2</span>'
      expect(@sidebar).to include '<span class="badge">15</span>'
      expect(@sidebar).to include '<span class="badge">3</span>'
      expect(@sidebar).to include '<span class="badge-optional">1</span> View'
      expect(@sidebar).to include '<span class="badge-optional">3</span> Downloads'
    end

    it "shows the statistics before the profile" do
      expect(@sidebar).to match(/Your Statistics.*Charles Francis Xavier/m)
    end
  end

  describe "main" do
    context "with activities and notifications" do
      before do
        @now = DateTime.now.to_i
        assign(:activity, [
          { action: 'so and so edited their profile', timestamp: @now },
          { action: 'so and so uploaded a file', timestamp: (@now - 360) }
        ])
      end

      it "includes recent activities and notifications" do
        render
        expect(rendered).to include "so and so edited their profile"
        expect(rendered).to include "6 minutes ago"
      end
    end

    context "with notifications" do
      before do
        assign(:notifications, FactoryGirl.create(:user_with_mail).mailbox.inbox)
      end

      it "shows a link to all notifications" do
        render
        expect(rendered).to include "See all notifications"
      end

      it "defaults to a limited number of notifications" do
        render
        expect(rendered).to include "Single File 9"
        expect(rendered).to_not include "Single File 2"
      end

      it "allows showing more notifications" do
        Sufia.config.max_notifications_for_dashboard = 6
        render
        expect(rendered).to include "Single File 1"
      end
    end

    context 'with transfers' do
      let(:user) { FactoryGirl.find_or_create(:jill) }
      let(:another_user) { FactoryGirl.find_or_create(:archivist) }
      let(:title1) { 'foobar' }
      let(:title2) { 'bazquux' }

      before do
        GenericWork.new(title: [title1]).tap do |w|
          w.apply_depositor_metadata(another_user.user_key)
          w.save!
          w.request_transfer_to(user)
        end
        GenericWork.new(title: [title2]).tap do |w|
          w.apply_depositor_metadata(user.user_key)
          w.save!
          w.request_transfer_to(another_user)
        end
        allow(controller).to receive(:current_user).and_return(user)
        assign(:incoming, ProxyDepositRequest.where(receiving_user_id: user.id))
        assign(:outgoing, ProxyDepositRequest.where(sending_user_id: user.id))
      end

      it 'renders received and sent transfer requests' do
        render
        expect(rendered).not_to include "You haven't received any work transfers requests"
        expect(rendered).not_to include "You haven't transferred any works"
        expect(rendered).to include title1
        expect(rendered).to include title2
      end
    end

    context "without activities and notifications" do
      it "includes headings for activities and notifications" do
        render
        expect(rendered).to include "User Activity"
        expect(rendered).to include "User Notifications"
      end

      it "shows no activities or notifications" do
        render
        expect(rendered).to include "User has no notifications"
        expect(rendered).to include "User has no recent activity"
      end
    end
  end
end
