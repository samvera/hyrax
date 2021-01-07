# frozen_string_literal: true
RSpec.describe 'Transferring work ownership:', type: :feature do
  include Selectors::Dashboard
  include Selectors::NewTransfers
  include Selectors::Transfers

  let(:original_owner) { FactoryBot.create(:user) }
  let(:new_owner) { FactoryBot.create(:user) }
  let(:work) do
    FactoryBot.create(:public_work,
                      title: ['little_generic_work'],
                      creator: ['little_generic_work.creator'],
                      resource_type: ["stuff"],
                      user: original_owner)
  end

  describe 'when I request a work transfer', :js do
    before { sign_in(original_owner) }

    context 'To myself' do
      before { transfer_ownership_of_work work, original_owner }

      it 'displays an appropriate error message' do
        expect(page).to have_content 'Specify a different user to receive the work'
      end
    end

    it 'if the new owner accepts it I should see it was accepted' do
      transfer_ownership_of_work(work, new_owner)
      expect(page).to have_content('Transfer request created')
      new_owner.proxy_deposit_requests.last.transfer!
      # refresh the page
      visit '/dashboard'
      expect(page.find('#outgoing-transfers')).to have_content 'Accepted'
    end

    it 'if I cancel it I should see it was cancelled' do
      transfer_ownership_of_work(work, new_owner)
      accept_confirm { first_sent_cancel_button.click }
      expect(page).to have_content 'Transfer canceled'
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
    end

    it 'I should be able to accept it' do
      visit '/dashboard'

      within('#notifications') do
        expect(page).to have_content "#{original_owner.name} wants to transfer a work to you"
      end
      first_received_accept_dropdown.click
      click_link 'accept-retain'
      expect(page).to have_content 'Transfer complete'
    end

    it 'I should be able to reject it' do
      visit '/dashboard'

      within('#notifications') do
        expect(page).to have_content "#{original_owner.name} wants to transfer a work to you"
      end
      accept_confirm { first_received_reject_button.click }
      expect(page).to have_content 'Transfer rejected'
    end
  end

  def transfer_ownership_of_work(work, new_owner)
    visit '/dashboard/my/works'

    db_item_actions_toggle(work).click
    click_link 'Transfer Ownership of Work'
    expect(page).to have_content I18n.t(:'hyrax.transfers.new.sr_only_description', work_title: work.title.first)
    new_owner_dropdown.click
    new_owner_search_field.set new_owner.user_key
    new_owner_search_result.click
    fill_in 'proxy_deposit_request[sender_comment]', with: 'Work transfer comments'
    accept_confirm { click_button "Transfer" }
  end
end
