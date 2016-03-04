module Locations
  def go_to_dashboard_works
    visit '/dashboard/works'
    expect(page).to have_selector('li.active', text: "My Works")
  end

  def go_to_user_profile
    first(".dropdown-toggle").click
    click_link "my profile"
  end
end

RSpec.configure do |config|
  config.include Locations
end
