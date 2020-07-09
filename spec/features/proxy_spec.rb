# frozen_string_literal: true
RSpec.describe 'proxy', type: :feature do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }

  describe 'add proxy in profile', :js do
    it "create a proxy, then deletes a proxy, and verifies deletion" do
      sign_in user
      # Prior to capturing the after sign in path, this code was later
      # re-signing to get to this captured path.
      after_signin_path = page.current_path
      click_link "Your activity"
      within 'div#proxy_management' do
        click_link "Manage Proxies"
      end
      expect(page).not_to have_css("td.depositor-name")

      # BEGIN create_proxy_using_partial
      find('a.select2-choice').click
      find(".select2-input").set(second_user.user_key)
      expect(page).to have_css("div.select2-result-label")
      find("div.select2-result-label").click
      # END create_proxy_using_partial

      expect(page).to have_css('td.depositor-name', text: second_user.user_key)
      expect(page).to have_link('Delete Proxy')

      click_link('Delete Proxy')

      # Go back to page and verify second_user is not a proxy.
      visit(after_signin_path)
      click_link "Your activity"
      within 'div#proxy_management' do
        click_link "Manage Proxies"
      end
      expect(page).not_to have_css('td.depositor-name', text: second_user.user_key)
      expect(page).not_to have_link('Delete Proxy')
    end

    it "does not allow you making yourself a proxy" do
      sign_in user
      click_link "Your activity"
      within 'div#proxy_management' do
        click_link "Manage Proxies"
      end

      expect(page).not_to have_css("td.depositor-name")

      # BEGIN create_proxy_using_partial
      find('a.select2-choice').click
      find(".select2-input").set(user.user_key)
      expect(page).to have_css("div.select2-result-label")
      find("div.select2-result-label").click
      # END create_proxy_using_partial

      within('#proxy-deny-modal') do
        expect(page).to have_content "You cannot make yourself a proxy"
        click_button('Close')
      end
    end
  end
end
