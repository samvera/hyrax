require 'spec_helper'

include Selectors::Header
include Selectors::Dashboard
include Selectors::NewTransfers
include Selectors::Transfers

describe 'Transferring file ownership:', :type => :feature do
  let(:original_owner) { FactoryGirl.create(:archivist, display_name: 'Original Owner') }
  let(:new_owner) { FactoryGirl.create(:jill, display_name: 'New Owner') }
  let!(:file) do
    GenericFile.new.tap do |f|
      f.title = ['little_file.txt']
      f.creator = ['little_file.txt_creator']
      f.resource_type = ["stuff" ]
      f.read_groups = ['public']
      f.apply_depositor_metadata(original_owner.user_key)
      f.save!
    end
  end

  before do
    sign_in original_owner
    go_to_dashboard_files
  end

  describe 'When I request a file transfer:', :js do
    context 'For a file I do not own' do
      pending 'The transfer option is not available' do
        fail
      end
    end

    context 'To myself' do
      before { transfer_ownership_of_file file, original_owner }
      it 'Displays an appropriate error message' do
        expect(page).to have_content 'Sending user must specify another user to receive the file'
      end
    end

    context 'To someone else' do
      before { transfer_ownership_of_file file, new_owner }
      it 'Creates a transfer request' do
        expect(page).to have_content 'Transfer request created'
      end
      context 'If the new owner accepts it' do
        before do
          new_owner.proxy_deposit_requests.last.transfer!
          user_utility_toggle.click
          click_link 'transfer requests'
        end
        specify 'I should see it was accepted' do
          expect(page.find('#outgoing-transfers')).to have_content 'Accepted'
        end
      end
      context 'If I cancel it' do
        before do
          user_utility_toggle.click
          click_link 'transfer requests'
          first_sent_cancel_button.click
        end
        specify 'I should see it was cancelled' do
          expect(page).to have_content 'Transfer canceled'
        end
      end
    end
  end

  describe 'When someone requests a file transfer to me', :js do
    before do
      # As the original_owner, transfer a file to the new_owner
      transfer_ownership_of_file file, new_owner
      # Become the new_owner so we can manage transfers sent to us
      sign_in new_owner
      visit '/dashboard'
      user_utility_toggle.click
      within '#user_utility_links' do
        click_link 'transfer requests'
      end
      expect(page).to have_content 'Transfer of Ownership'
    end
    specify 'I should receive a notification' do
      user_notifications_link.click
      expect(page).to have_content "#{original_owner.name} wants to transfer a file to you"
    end
    specify 'I should be able to accept it' do
      first_received_accept_dropdown.click
      click_link 'Allow depositor to retain edit access'
      expect(page).to have_content 'Transfer complete'
    end
    specify 'I should be able to reject it' do
      first_received_reject_button.click
      expect(page).to have_content 'Transfer rejected'
    end
  end

  def transfer_ownership_of_file(file, new_owner)
    db_item_actions_toggle(file).click
    click_link 'Transfer Ownership of File'
    expect(page).to have_content "Select a user to transfer #{file.title.first} to, add optional comments and then press transfer."
    new_owner_dropdown.click
    new_owner_search_field.set new_owner.user_key
    new_owner_search_result.click
    fill_in 'proxy_deposit_request[sender_comment]', with: 'File transfer comments'
    submit_button.click
  end
end
