require 'spec_helper'

describe "creating an embargoed object" do
  let(:user) { FactoryGirl.create(:user) }
  before do
    sign_in user
    visit '/'
  end

  it "can be created, displayed and updated" do
    click_link 'New Generic Work'
    fill_in 'Title', with: 'Embargo test'
    check 'I have read and accept the contributor license agreement'
    choose 'Embargo'
    select 'Private', from: 'Visibility during embargo'
    select 'Open Access', from: 'Visibility after embargo'
    click_button 'Create Generic work'

    click_link "Edit This Generic Work"
    click_link "Embargo Management Page"

    expect(page).to have_content("This work is under embargo.")

    fill_in "Embargo release date", with: 2.days.from_now.to_s

    click_button "Update Embargo"
    expect(page).to have_content(2.days.from_now.strftime '%F')
  end
end
