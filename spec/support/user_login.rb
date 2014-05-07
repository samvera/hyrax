module UserLogin
  def go_to_dashboard
    visit '/'
    first('a.dropdown-toggle').click
    click_link('my dashboard')
    # causes selenium to wait until text appears on the page
    page.should have_content('My Dashboard')
  end
end
