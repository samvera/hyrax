RSpec.describe 'Transferring work ownership:', type: :feature do
  include Selectors::Dashboard
  include Selectors::NewTransfers
  include Selectors::Transfers

  let(:original_owner) { create(:user) }
  let(:new_owner) { create(:user) }
  let!(:work) do
    create(:public_work,
           title: ['little_generic_work'],
           creator: ['little_generic_work.creator'],
           resource_type: ["stuff"],
           user: original_owner)
  end

  describe 'When I request a work transfer:', :js do
    before do
      sign_in original_owner
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
          # refresh the page
          visit '/dashboard'
        end
        it 'I should see it was accepted' do
          expect(page.find('#outgoing-transfers')).to have_content 'Accepted'
        end
      end

      context 'If I cancel it' do
        before do
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
      ProxyDepositRequest.create!(work_id: work.id,
                                  sending_user: original_owner,
                                  transfer_to: new_owner.user_key)

      # Become the new_owner so we can manage transfers sent to us
      sign_in new_owner
      visit '/dashboard'
      expect(page).to have_content 'Transfer of Ownership'
    end

    it 'I should be able to accept it' do
      within('#notifications') do
        expect(page).to have_content "#{original_owner.name} wants to transfer a work to you"
      end
      first_received_accept_dropdown.click
      click_link 'Allow depositor to retain edit access'
      expect(page).to have_content 'Transfer complete'
    end

    it 'I should be able to reject it' do
      within('#notifications') do
        expect(page).to have_content "#{original_owner.name} wants to transfer a work to you"
      end
      first_received_reject_button.click
      expect(page).to have_content 'Transfer rejected'
    end
  end

  def transfer_ownership_of_work(work, new_owner)
    visit '/dashboard/my/works'

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
