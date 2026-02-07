# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'hyrax/homepage/robots.text.erb', type: :view do
  it 'includes user agent directive' do
    render
    expect(rendered).to include('User-agent: *')
  end

  it 'includes sitemap with dynamic hostname' do
    render
    expect(rendered).to include('Sitemap: http://test.host/sitemap')
  end
end
