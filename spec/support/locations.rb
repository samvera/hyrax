module Locations
  def go_to_user_profile
    within '#user_utility_links' do
      first(:xpath, ".//li[contains(@class, 'dropdown') and not(contains(@class, 'nav-item'))]/a").click
      click_link 'View Profile'
    end
  end
end

RSpec.configure do |config|
  config.include Locations
end
