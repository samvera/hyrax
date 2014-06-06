require 'spec_helper'

describe "creating an leased object" do
  let(:user) { FactoryGirl.create(:user) }
  before do
    sign_in user
    visit '/'
  end

  it "can be created, displayed and updated" do
    click_link 'New Generic Work'
    fill_in 'Title', with: 'Lease test'
    check 'I have read and accept the contributor license agreement'
    choose 'Lease'
    select 'Open Access', from: 'Visibility during lease'
    select 'Private', from: 'Visibility after lease'
    click_button 'Create Generic work'

    click_link "Edit This Generic Work"
    click_link "Lease Management Page"

    expect(page).to have_content("This work is under lease.")

    fill_in "Lease expiration date", with: 2.days.from_now.to_s

    click_button "Update Lease"
    expect(page).to have_content(2.days.from_now.strftime '%F')
  end
end
