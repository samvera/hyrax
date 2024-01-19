# frozen_string_literal: true
RSpec.describe 'Adding a work to multiple collections', :clean_repo, type: :feature, js: true do
  include Selectors::Dashboard
  let(:admin_user) { create(:admin, email: 'admin@example.com') }
  let(:single_membership_type_1) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 1') }
  let(:single_membership_type_2) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 2') }
  let(:multi_membership_type_1) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 1') }
  let(:multi_membership_type_2) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 2') }

  before do
    sign_in admin_user
  end

  describe 'when both collections support multiple membership' do
    let(:old_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: multi_membership_type_1, title: ['OldCollectionTitle']) }
    let!(:work) do
      FactoryBot.valkyrie_create(:monograph,
                                 depositor: admin_user.user_key,
                                 member_of_collection_ids: [old_collection.id],
                                 title: ['The highly valued work that everyone wants in their collection'])
    end

    context 'and are of different types' do
      let!(:new_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: multi_membership_type_2, title: ['NewCollectionTitle']) }

      it 'then the work is added to both collections' do
        # Add to second multi-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        select_member_of_collection(new_collection)
        click_button 'Save changes'

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end

    context 'and are of the same type' do
      let!(:new_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: multi_membership_type_1, title: ['NewCollectionTitle']) }

      it 'then the work is added to both collections' do
        # Add to second multi-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        select_member_of_collection(new_collection)
        click_button 'Save changes'

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end
  end

  describe 'when both collections require single membership' do
    let(:old_collection) { FactoryBot.valkyrie_create(:hyrax_collection, :with_permission_template, user: admin_user, collection_type: single_membership_type_1, title: ['OldCollectionTitle']) }
    let!(:work) do
      FactoryBot.valkyrie_create(:monograph,
                                 depositor: admin_user.user_key,
                                 member_of_collection_ids: [old_collection.id],
                                 title: ['The highly valued work that everyone wants in their collection'],
                                 creator: ["Fred"], record_info: ['123'],
                                 keyword: ['test'], rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/'])
    end

    context 'and are of different types' do
      let!(:new_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: single_membership_type_2, title: ['NewCollectionTitle']) }

      it 'then the work is added to both collections' do
        # Add to second single-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        select_member_of_collection(new_collection)
        click_button 'Save changes'

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end

    context 'and are of the same type' do
      let!(:new_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: single_membership_type_1, title: ['NewCollectionTitle']) }

      context 'then the work fails to add to the second collection' do
        it 'from the dashboard->works batch add to collection' do
          # Attempt to add to second single-membership collection of the same type
          visit '/dashboard/my/works'
          check 'check_all'
          click_button 'Add to collection' # opens the modal
          select_member_of_collection(new_collection)
          click_button 'Save changes'

          # forwards to collections index page and shows flash message
          within('section.tabs-row') do
            expect(page).to have_link 'All Collections'
            expect(page).to have_link 'Your Collections'
          end

          err_message = "Error: You have specified more than one of the same single-membership collection type " \
                        "(type: Single-membership 1, collections: #{new_collection.title.first} and #{old_collection.title.first})"
          expect(page).to have_selector '.alert', text: err_message
        end

        it "from the work's edit form Relationships tab", js: true do
          # Attempt to add to second single-membership collection of the same type
          visit '/dashboard/my/works'
          within("\#document_#{work.id}") do
            click_button "Select"
            click_link "Edit work"
          end
          click_link "Relationships"

          select_collection(new_collection)
          check('agreement')
          choose('Public', option: 'open')

          within('div#savewidget') do
            element = nil
            all('input').each { |i| element = i if i.value == 'Save changes' }
            element.click
          end

          err_message = "Error: You have specified more than one of the same single-membership collection type " \
                        "(type: Single-membership 1, collections: #{new_collection.title.first} and #{old_collection.title.first})"
          expect(page).to have_selector '.alert', text: err_message
        end

        it "from the collection's show page Add to collection" do
          # Attempt to add to second single-membership collection of the same type
          visit "/dashboard/collections/#{new_collection.id}"
          click_link 'Add existing works'
          check 'check_all'
          click_button 'Add to collection' # opens the modal
          within('div#collection-list-container') do
            expect(page).to have_selector "#member_of_collection_ids[value=\"#{new_collection.id}\"]", visible: false
            expect(page).to have_selector "#member_of_collection_label[value=\"#{new_collection.title.first}\"]"
            click_button 'Save changes'
          end
          # forwards to collections index page and shows flash message
          within('section.tabs-row') do
            expect(page).to have_link 'All Collections'
            expect(page).to have_link 'Your Collections'
          end

          err_message = "Error: You have specified more than one of the same single-membership collection type " \
                        "(type: Single-membership 1, collections: #{new_collection.title.first} and #{old_collection.title.first})"
          expect(page).to have_selector '.alert', text: err_message
        end
      end
    end
  end

  describe 'when adding a work already in a collection' do
    let!(:work) do
      FactoryBot.valkyrie_create(:monograph,
                                 depositor: admin_user.user_key,
                                 member_of_collection_ids: [old_collection.id],
                                 title: ['The highly valued work that everyone wants in their collection'])
    end

    context 'allowing multi-membership' do
      let(:old_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: multi_membership_type_1, title: ['CollectionTitle']) }
      let!(:new_collection) { old_collection }

      it 'then the add is treated as a success' do
        # Re-add to same multi-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        select_member_of_collection(new_collection)
        click_button 'Save changes'

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end

    context 'requiring single-membership' do
      let(:old_collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: admin_user, collection_type: single_membership_type_1, title: ['CollectionTitle']) }
      let!(:new_collection) { old_collection }

      it 'then the add is treated as a success' do
        # Re-add to same single-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        select_member_of_collection(new_collection)
        click_button 'Save changes'

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end
  end
end
