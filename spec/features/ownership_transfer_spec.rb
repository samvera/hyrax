include Selectors::Header
include Selectors::Dashboard
include Selectors::NewTransfers
include Selectors::Transfers

describe 'Transferring work ownership:', type: :feature do
  let(:original_owner) { create(:user) }
  let(:new_owner) { create(:user) }
  let!(:work) do
    GenericWork.new.tap do |f|
      f.title = ['little_generic_work']
      f.creator = ['little_generic_work.creator']
      f.resource_type = ["stuff"]
      f.read_groups = ['public']
      f.apply_depositor_metadata(original_owner.user_key)
      f.save!
    end
  end

  before do
    sign_in original_owner
    go_to_dashboard_works
  end

  describe 'When I request a work transfer:', :js do
    context 'For a work I do not own' do
      pending 'The transfer option is not available' do
        raise
      end
    end

    context 'To myself' do
      before { transfer_ownership_of_work work, original_owner }
      it 'Displays an appropriate error message' do
        expect(page).to have_content 'Sending user must specify another user to receive the work'
      end
    end

    context 'To someone else' do
      before { transfer_ownership_of_work work, new_owner }
      it 'Creates a transfer request' do
        expect(page).to have_content 'Transfer request created'
      end
      context 'If the new owner accepts it' do
        before do
          new_owner.proxy_deposit_requests.last.transfer!
          nav_toggle 'Dashboard', 'Transfer'
        end
        it 'I should see it was accepted' do
          expect(page.find('#outgoing-transfers')).to have_content 'Accepted'
        end
      end
      context 'If I cancel it' do
        before do
          nav_toggle 'Dashboard', 'Transfer'
          first_sent_cancel_button.click
        end
        it 'I should see it was cancelled' do
          expect(page).to have_content 'Transfer canceled'
        end
      end
    end
  end

  describe 'When someone requests a work transfer to me', :js do
    before do
      # As the original_owner, transfer a work to the new_owner
      transfer_ownership_of_work work, new_owner
      # Become the new_owner so we can manage transfers sent to us
      sign_in new_owner
      visit '/dashboard'
      nav_toggle 'Dashboard', 'Transfer'
      expect(page).to have_content 'Transfer of Ownership'
    end
    it 'I should receive a notification' do
      nav_toggle('Dashboard', 'Notifications')
      expect(page).to have_content "#{original_owner.name} wants to transfer a work to you"
    end
    it 'I should be able to accept it' do
      first_received_accept_dropdown.click
      click_link 'Allow depositor to retain edit access'
      expect(page).to have_content 'Transfer complete'
    end
    it 'I should be able to reject it' do
      first_received_reject_button.click
      expect(page).to have_content 'Transfer rejected'
    end
  end

  def transfer_ownership_of_work(work, new_owner)
    db_item_actions_toggle(work).click
    click_link 'Transfer Ownership of Work'
    expect(page).to have_content "Select a user to transfer #{work.title.first} to, add optional comments and then press transfer."
    new_owner_dropdown.click
    new_owner_search_field.set new_owner.user_key
    new_owner_search_result.click
    fill_in 'proxy_deposit_request[sender_comment]', with: 'Work transfer comments'
    submit_button.click
  end
end
