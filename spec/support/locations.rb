module Locations
  def go_to_dashboard
    visit '/dashboard'
    # causes selenium to wait until text appears on the page
    page.should have_content('My Dashboard')
  end

  def go_to_dashboard_files
    visit '/dashboard/files'
    expect(page).to have_selector('li.active', text: "My Files")
  end

  def go_to_dashboard_collections
    visit '/dashboard/collections'
    page.should have_content('My Collections')
  end

  def go_to_dashboard_shares
    visit '/dashboard/shares'
    page.should have_content('Files Shared with Me')
  end

  def go_to_dashboard_highlights
    visit '/dashboard/highlights'
    page.should have_content('My Highlights')
  end

  def go_to_user_profile
    first(".dropdown-toggle").click
    click_link "my profile"
  end
end

RSpec.configure do |config|
  config.include Locations
end
