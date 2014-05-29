require 'spec_helper'

describe "Adding a work with external links" do
  let(:user) { FactoryGirl.create(:user) }
  before do
    sign_in user
    visit '/'
  end

  it "adds external links" do
    click_link 'New Generic Work'
    fill_in 'External link', with: 'http://dp.la'
    fill_in 'Title', with: 'DPLA link'
    check 'I have read and accept the contributor license agreement'
    click_button 'Create Generic work'
    expect(page).to have_link 'http://dp.la'

    click_link 'Add an External Link'
    fill_in 'External link', with: 'http://loc.gov'
    click_button 'Add External Link to Generic Work'
    expect(page).to have_link 'http://dp.la'
    expect(page).to have_link 'http://loc.gov'
  end

end
