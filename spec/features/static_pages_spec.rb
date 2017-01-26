require 'spec_helper'

RSpec.describe "The static pages" do
  scenario do
    visit root_path
    click_link "About"
    click_link "Help"
  end
end
