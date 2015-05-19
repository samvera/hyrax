require 'spec_helper'

include Selectors::Header
include Selectors::Dashboard
include Selectors::NewTransfers
include Selectors::Transfers

describe 'Transferring work ownership:', :type => :feature do
  let(:original_owner) { FactoryGirl.create(:archivist, display_name: 'Original Owner') }
  let(:new_owner) { FactoryGirl.create(:jill, display_name: 'New Owner') }
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
    # sign_in original_owner
    # go_to_dashboard_files
  end

  describe 'When I request a work transfer:', :js do
    context 'For a work I do not own' do
      pending 'The transfer option is not available' do
        fail
      end
    end

    context 'To myself' do
      pending 'The transfer option is not available' do
        fail
      end
    end

    context 'To someone else' do
      pending 'The transfer option is not available' do
        fail
      end
      context 'If the new owner accepts it' do
      pending 'The transfer option is not available' do
        fail
      end
      end
      context 'If I cancel it' do
      pending 'The transfer option is not available' do
        fail
      end
      end
    end
  end

  describe 'When someone requests a work transfer to me', :js do
      pending 'The transfer option is not available' do
        fail
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
