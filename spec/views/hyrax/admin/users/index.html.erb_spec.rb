RSpec.describe 'hyrax/admin/users/index.html.erb', type: :view do
  let(:presenter) { Hyrax::Admin::UsersPresenter.new }
  let(:users) { [] }

  before do
    (1..4).each { |i| users << build(:user, display_name: "user#{i}", email: "email#{i}@example.com", last_sign_in_at: Time.zone.now - 15.minutes, created_at: Time.zone.now - 3.days) }
    allow(presenter).to receive(:users).and_return(users)
    assign(:presenter, presenter)
  end

  it "draws user list with all users" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_content("Username")
    expect(page).to have_content("Roles")
    expect(page).to have_content("Last access")
    (1..4).each do |i|
      expect(page).to have_content("email#{i}@example.com")
    end
  end
end
