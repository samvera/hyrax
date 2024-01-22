# frozen_string_literal: true
RSpec.describe 'hyrax/users/index.html.erb', type: :view do
  let(:join_date) { 5.days.ago }
  let(:application_name) { I18n.t('hyrax.product_name', default: 'Hyrax') }

  before do
    users = []
    (1..25).each { |i| users << stub_model(User, name: "name#{i}", user_key: "user#{i}", created_at: join_date) }
    allow(User).to receive(:all).and_return(users)
    relation = User.all
    allow(relation).to receive(:limit_value).and_return(10)
    allow(relation).to receive(:current_page).and_return(1)
    allow(relation).to receive(:total_pages).and_return(3)
    allow(view).to receive(:number_of_works).and_return(0)
    assign(:users, relation)
  end

  it "draws user list" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_content("#{application_name} Users")
    expect(page).to have_content("Works Created")
    (1..10).each do |i|
      expect(page).to have_content("user#{i}")
    end
  end
end
