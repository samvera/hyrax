describe 'hyrax/users/index.html.erb', type: :view do
  let(:query) { '' }
  let(:authentication_key) { Devise.authentication_keys.first }
  let(:presenter) { Hyrax::UsersPresenter.new(query: query, authentication_key: authentication_key) }
  let(:users) { [] }

  before do
    (1..11).each { |i| users << FactoryGirl.create(:user, display_name: "user#{i}", email: "email#{i}@example.com") }
    allow(presenter).to receive(:users).and_return(users)
    assign(:presenter, presenter)
  end

  it "draws user list" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_content("Username")
    expect(page).to have_content("Roles")
    expect(page).to have_content("Last access")
    (1..10).each do |i|
      expect(page).to have_content("email#{i}@example.com")
    end
  end
end
