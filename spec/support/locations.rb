module Locations
  def go_to_dashboard
    visit '/dashboard'
    # causes selenium to wait until text appears on the page
    expect(page).to have_content('My Dashboard')
  end

  def go_to_dashboard_files
    visit '/dashboard/files'
    expect(page).to have_selector('li.active', text: "My Works")
  end

  def go_to_dashboard_collections
    visit '/dashboard/collections'
    expect(page).to have_content('My Collections')
  end

  def go_to_dashboard_shares
    visit '/dashboard/shares'
    expect(page).to have_content('Files Shared with Me')
  end

  def go_to_dashboard_highlights
    visit '/dashboard/highlights'
    expect(page).to have_content('My Highlights')
  end

  def go_to_user_profile
    first(".dropdown-toggle").click
    click_link "my profile"
  end
end

RSpec.configure do |config|
  config.include Locations
end
