# frozen_string_literal: true
RSpec.describe "The static pages", :clean_repo do
  it do
    visit root_path
    click_link "About"
    click_link "Help"
  end
end
