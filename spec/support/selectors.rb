# frozen_string_literal: true
module Selectors
  module Dashboard
    def db_item_actions_toggle(item)
      within "#document_#{item.id}" do
        find '.dropdown-toggle'
      end
    end

    # For use with javascript user selector that allows for searching for an existing user
    # and granting them permission to an object.
    # @param [User] user to select
    # @param [String] role granting the user permission (e.g. 'Manager' | 'Depositor' | 'Viewer')
    def select_user(user, role = 'Depositor')
      first('a.select2-choice').click
      find('.select2-input').set(user.user_key)
      sleep 1
      first('div.select2-result-label').click
      within('div.add-users') do
        select(role)
        find('input.edit-collection-add-sharing-button').click
      end
    end

    # For use with javascript collection selector that allows for searching for an existing collection from works relationship tab.
    # Adds the collection and validates that the collection is listed in the Collection Relationship table once added.
    # @param [Collection] collection to select
    def select_collection(collection)
      first('a.select2-choice').click
      find('.select2-input').set(collection.title.first)
      expect(page).to have_css('div.select2-result-label')
      first('div.select2-result-label').click
      first('[data-behavior~=add-relationship]').click
      within('[data-behavior~=collection-relationships]') do
        within('table.table.table-striped') do
          expect(page).to have_content(collection.title.first)
        end
      end
    end

    # For use with javascript collection selector that allows for searching for an existing collection from add to collection modal.
    # Does not save the selection.  The calling test is expected to click Save and validate the collection membership was added to the work.
    # @param [Collection] collection to select
    def select_member_of_collection(collection) # rubocop:disable Metrics/MethodLength
      find('#s2id_member_of_collection_ids').click
      find('.select2-input').set(collection.title.first)
      # Crude way of waiting for the AJAX response
      select2_results = []
      time_elapsed = 0
      while select2_results.empty? && time_elapsed < 30
        begin_time = Time.now.to_f
        doc = Nokogiri::XML.parse(page.body)
        select2_results = doc.xpath('//html:li[contains(@class,"select2-result")]', html: 'http://www.w3.org/1999/xhtml')
        end_time = Time.now.to_f
        time_elapsed += end_time - begin_time
      end
      expect(page).to have_css('.select2-result')
      within ".select2-result" do
        find("span", text: collection.title.first).click
      end
    end
  end

  module NewTransfers
    def new_owner_dropdown
      find '#s2id_proxy_deposit_request_transfer_to'
    end

    def new_owner_search_field
      within '#select2-drop' do
        find '.select2-input'
      end
    end

    def new_owner_search_result
      within '#select2-drop' do
        find '.select2-result-selectable'
      end
    end
  end

  module Transfers
    def first_sent_cancel_button
      within '#outgoing-transfers' do
        find '.btn.btn-danger'
      end
    end

    def first_received_accept_dropdown
      within '#incoming-transfers' do
        find '.dropdown-toggle.accept'
      end
    end

    def first_received_reject_button
      within '#incoming-transfers' do
        find '.btn.btn-danger'
      end
    end
  end
end
