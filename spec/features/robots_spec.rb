# frozen_string_literal: true
require 'rails_helper'

RSpec.feature 'Dynamic Robots' do
  let(:app_host) { Capybara.app_host || 'http://www.example.com' }
  it 'points to the right sitemap' do
    visit '/robots.txt'
    expect(page).to have_content("User-agent: *")
    expect(page).to have_content("Sitemap: #{app_host}/sitemap")
  end
end
