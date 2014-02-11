require 'spec_helper'

describe 'users/index.html.erb' do

  let(:join_date) { 5.days.ago }
  before do
    users = []
    (1..25).each  {|i| users << stub_model(User, name: "name#{i}", user_key: "user#{i}", created_at: join_date)}
    User.stub_chain(:all).and_return(users)
    relation = User.all
    allow(relation).to receive(:limit_value).and_return(10)
    allow(relation).to receive(:current_page).and_return(1)
    allow(relation).to receive(:total_pages).and_return(3)
    assign(:users, relation)
  end

  it "should draw user list" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_content("ScholarSphere Users")
    (1..10).each  do |i|
      expect(page).to have_content("user#{i}")
    end
  end

end
