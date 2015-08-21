require 'spec_helper'

describe "admin/stats/index.html.erb" do
  let(:presenter) do
    Sufia::AdminStatsPresenter.new.tap do |p|
      p.files_count = {}
      p.top_formats = []
      p.users_stats = {}
      p.recent_users = []
      p.deposit_stats = {}
      p.depositors = []
    end
  end
  before do
    assign(:presenter, presenter)
  end

  context "default depositors" do
    let(:top_5_active_users) do
      users = {}
      5.times { |i| users[i.to_s] = i }
      users
    end
    before do
      presenter.active_users = top_5_active_users
      render
    end
    it "shows top 5 depositors and option to view more" do
      expect(rendered).to have_content("(top 5)")
      expect(rendered).to have_content("View top 20")
    end
  end

  context "top 20 depositors" do
    let(:top_20_active_users) do
      users = {}
      20.times { |i| users[i.to_s] = i }
      users
    end
    before do
      presenter.active_users = top_20_active_users
      params[:dep_count] = 20
      render
    end
    it "shows top 20 depositors, without an option to view more" do
      expect(rendered).to have_content("(top 20)")
      expect(rendered).to_not have_content("View top 20")
    end
  end
end
