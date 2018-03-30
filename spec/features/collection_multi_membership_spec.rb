RSpec.describe 'Adding a work to multiple collections', type: :feature, clean_repo: true, js: true do
  let(:admin_user) { create(:admin, email: 'admin@example.com') }
  let(:single_membership_type_1) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 1') }
  let(:single_membership_type_2) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 2') }
  let(:multi_membership_type_1) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 1') }
  let(:multi_membership_type_2) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 2') }

  before do
    sign_in admin_user
  end

  describe 'when both collections support multiple membership' do
    let(:old_collection) { create(:collection_lw, user: admin_user, collection_type_gid: multi_membership_type_1.gid) }
    let!(:work) { create(:generic_work, user: admin_user, member_of_collections: [old_collection], title: ['The highly valued work that everyone wants in their collection']) }

    context 'and are of different types' do
      let!(:new_collection) { create(:collection_lw, user: admin_user, collection_type_gid: multi_membership_type_2.gid) }

      it 'then the work is added to both collections' do
        skip
        # Add to second multi-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose new_collection.title.first # selects the collection
          click_button 'Save changes'
        end

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end

    context 'and are of the same type' do
      skip
      let!(:new_collection) { create(:collection_lw, user: admin_user, collection_type_gid: multi_membership_type_1.gid) }

      it 'then the work is added to both collections' do
        # Add to second multi-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose new_collection.title.first # selects the collection
          click_button 'Save changes'
        end

        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end
  end

  describe 'when both collections require single membership' do
    let(:old_collection) { create(:collection_lw, user: admin_user, collection_type_gid: single_membership_type_1.gid) }
    let!(:work) { create(:generic_work, user: admin_user, member_of_collections: [old_collection], title: ['The highly valued work that everyone wants in their collection'],
                               creator: ["Fred"], keyword: ['test'], rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/']) }

    context 'and are of different types' do
      let!(:new_collection) { create(:collection_lw, user: admin_user, collection_type_gid: single_membership_type_2.gid) }

      it 'then the work is added to both collections' do
        # Add to second single-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose new_collection.title.first # selects the collection
          click_button 'Save changes'
        end
        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end

    context 'and are of the same type' do
      let!(:new_collection) { create(:collection_lw, user: admin_user, collection_type_gid: single_membership_type_1.gid) }
      let!(:single_collection) { create(:collection_lw, user: admin_user, collection_type_gid: single_membership_type_1.gid) }

      context 'then the work fails to add to the second collection' do
        it 'from the dashboard->works batch add to collection' do
          # Attempt to add to second single-membership collection of the same type
          visit '/dashboard/my/works'
          check 'check_all'
          click_button 'Add to collection' # opens the modal
          within('div#collection-list-container') do
            choose new_collection.title.first # selects the collection
            click_button 'Save changes'
          end
          # forwards to collections index page and shows flash message
          expect(page).to have_link 'All Collections'
          expect(page).to have_link 'Your Collections'

          err_message = "Error: You have specified more than one of the same single-membership collection types: " \
                        "Single-membership 1 (#{new_collection.title.first} and #{old_collection.title.first})"
          expect(page).to have_selector '.alert', text: err_message
        end

        it "from the work's edit form Relationships tab", js: true do
          # skip 'Needs additional work to find and select the second collection'
          # Attempt to add to second single-membership collection of the same type

          visit edit_hyrax_generic_work_path(work)
          click_link "Relationships"

          first('a.select2-choice').click
          find('.select2-input').set(new_collection.title.first)
          expect(page).to have_css('div.select2-result-label')
          first('div.select2-result-label').click
          first('[data-behavior~=add-relationship]').click
          within('[data-behavior~=collection-relationships]') do
            within('table.table.table-striped') do
              expect(page).to have_content(new_collection.title.first)
            end
          end
          check('agreement')
          sleep 3
          choose('generic_work_visibility_open')
          sleep 3

          within('div#savewidget') do
           element = nil
           all('input').each { |i| element = i if i.value == 'Save changes' }
           element.click
          end

          err_message = "Single collection Error: You have specified more than one of the same single-membership collection types: Single-membership 1 (Collection Title 1 and Collection Title 2)"
          expect(page).to have_selector '.help-block', text: err_message
        end

        it "from the collection's show page Add to collection" do
          # Attempt to add to second single-membership collection of the same type
          visit "/dashboard/collections/#{new_collection.id}"
          click_link 'Add existing works'
          check 'check_all'
          click_button 'Add to collection' # opens the modal
          within('div#collection-list-container') do
            choose new_collection.title.first # selects the collection
            click_button 'Save changes'
          end
          # forwards to collections index page and shows flash message
          expect(page).to have_link 'All Collections'
          expect(page).to have_link 'Your Collections'

          err_message = "Error: You have specified more than one of the same single-membership collection types: " \
                        "Single-membership 1 (#{new_collection.title.first} and #{old_collection.title.first})"
          expect(page).to have_selector '.alert', text: err_message
        end
      end
    end
  end

  describe 'when adding a work already in a collection' do
    skip
    let!(:work) { create(:generic_work, user: admin_user, member_of_collections: [old_collection], title: ['The highly valued work that everyone wants in their collection']) }

    context 'allowing multi-membership' do
      let(:old_collection) { create(:collection_lw, user: admin_user, collection_type_gid: multi_membership_type_1.gid) }
      let!(:new_collection) { old_collection }

      it 'then the add is treated as a success' do
        # Re-add to same multi-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose new_collection.title.first # selects the collection
          click_button 'Save changes'
        end
        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end

    context 'requiring single-membership' do
      let(:old_collection) { create(:collection_lw, user: admin_user, collection_type_gid: single_membership_type_1.gid) }
      let!(:new_collection) { old_collection }

      it 'then the add is treated as a success' do
        # Re-add to same single-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose new_collection.title.first # selects the collection
          click_button 'Save changes'
        end
        # forwards to collection show page
        expect(page).to have_content new_collection.title.first
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
      end
    end
  end
end
