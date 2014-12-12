require 'spec_helper'

describe 'proxy', :type => :feature do
  let(:user) { FactoryGirl.find_or_create(:archivist) }
  let(:second_user) { FactoryGirl.find_or_create(:jill) }

  describe 'add proxy in profile', :js do
    it "creates a proxy" do
      sign_in user
      visit "/"
      go_to_user_profile
      click_link "Edit Your Profile"
      expect(first("td.depositor-name")).to be_nil
      create_proxy_using_partial(second_user)
      expect(page).to have_css('td.depositor-name', text: second_user.user_key)
    end
  end

  describe 'use a proxy' do
    before do
      ProxyDepositRights.create!(grantor: second_user, grantee: user)
    end

    # TODO: Finish this spec
    xit "allows on-behalf-of deposit" do
      sign_in user
      visit '/'
      first('a.dropdown-toggle').click
      click_link('upload')
      within('#fileupload') do
        expect(page).to have_content('I have read')
        check("terms_of_service")
      end
      select(second_user.user_key, from: 'on_behalf_of')
      test_file_path = File.expand_path('../../fixtures/small_file.txt', __FILE__)
      page.execute_script(%Q{$("input[type=file]").first().css("opacity", "1").css("-moz-transform", "none");$("input[type=file]").first().attr('id',"fileselect");})
      attach_file("fileselect", test_file_path)
      redirect_url = find("#redirect-loc", visible: false).text
      click_button('Start upload')
      expect(page).to have_content('Apply Metadata')
      fill_in('generic_file_title', with: 'MY Title for the World')
      fill_in('generic_file_tag', with: 'test')
      fill_in('generic_file_creator', with: 'me')
      click_button('upload_submit')
      click_link('Files Shared with Me')
      expect(page).to have_content "MY Title for the World"
      first('i.glyphicon-chevron-right').click
      # TODO: need to remove all files prior to this test. Fedora it stil retaining leftovers
      first('.expanded-details').click_link(second_user.email)
    end
  end
end
