require 'spec_helper'

describe 'embargo' do
  let(:user) { FactoryGirl.create(:user) }
  before do
    sign_in user
  end
  describe "creating an embargoed object" do
    before do
      visit '/'
    end

    let(:future_date) { 2.days.from_now }

    it "can be created, displayed and updated" do
      click_link 'New Generic Work'
      fill_in 'Title', with: 'Embargo test'
      check 'I have read and accept the contributor license agreement'
      choose 'Embargo'
      select 'Private', from: 'Restricted to'
      select 'Open Access', from: 'then open it up to'
      click_button 'Create Generic work'

      click_link "Edit This Generic Work"
      click_link "Embargo Management Page"

      expect(page).to have_content("This work is under embargo.")

      fill_in "until", with: future_date.to_s

      click_button "Update Embargo"
      expect(page).to have_content(future_date.to_date.to_formatted_s(:long_ordinal))
    end
  end

  describe "managing embargoes" do
    before do
      # admin privs
      allow_any_instance_of(Ability).to receive(:user_groups).and_return(['admin'])
    end

    it "should show lists of objects under lease" do
      visit '/embargoes'
      expect(page).to have_content 'Manage Embargoes'
    end
  end
end
