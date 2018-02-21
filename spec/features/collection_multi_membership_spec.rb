RSpec.describe 'Adding a work to multiple collections', type: :feature, clean_repo: true, js: true, with_nested_reindexing: true do
  let!(:admin_user) { create(:admin, email: 'admin@example.com') }
  let!(:single_membership_type_1) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 1') }
  let!(:single_membership_type_2) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 2') }
  let!(:multi_membership_type_1) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 1') }
  let!(:multi_membership_type_2) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 2') }

  let!(:col1_sm_1) { create(:collection_lw, id: 'col1_sm_1', title: ['Collection 1 for SM1'], user: admin_user, collection_type_gid: single_membership_type_1.gid) }
  let!(:col2_sm_1) { create(:collection_lw, id: 'col2_sm_1', title: ['Collection 2 for SM1'], user: admin_user, collection_type_gid: single_membership_type_1.gid) }
  let!(:col3_sm_2) { create(:collection_lw, id: 'col3_sm_2', title: ['Collection 3 for SM2'], user: admin_user, collection_type_gid: single_membership_type_2.gid) }
  let!(:col4_mm_1) { create(:collection_lw, id: 'col4_mm_1', title: ['Collection 4 for MM1'], user: admin_user, collection_type_gid: multi_membership_type_1.gid) }
  let!(:col5_mm_1) { create(:collection_lw, id: 'col5_mm_1', title: ['Collection 5 for MM1'], user: admin_user, collection_type_gid: multi_membership_type_1.gid) }
  let!(:col6_mm_2) { create(:collection_lw, id: 'col6_mm_2', title: ['Collection 6 for MM2'], user: admin_user, collection_type_gid: multi_membership_type_2.gid) }

  let!(:work) { create(:generic_work, user: admin_user, title: ['The highly valued work that everyone wants in their collection']) }

  before do
    admin_user
    sign_in admin_user
    work
  end

  describe 'when both collections support multiple membership' do
    context 'and are of different types' do
      before do
        col4_mm_1
        col6_mm_2
      end

      it 'then the work is added to both collections' do
        # Add to the first multi-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 4 for MM1' # selects the collection
          click_button "Save changes"
        end

        # forwards to collection show page
        expect(page).to have_content(col4_mm_1.title.first)
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content 'The highly valued work that everyone wants in their collection'

        # Add to second multi-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 6 for MM2' # selects the collection
          click_button 'Save changes'
        end
        # forwards to collection show page
        expect(page).to have_content(col6_mm_2.title.first)
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content 'The highly valued work that everyone wants in their collection'
      end
    end

    context 'and are of the same type' do
      it 'then the work is added to both collections' do
        # Add to the first multi-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 4 for MM1' # selects the collection
          click_button "Save changes"
        end

        # forwards to collection show page
        expect(page).to have_content(col4_mm_1.title.first)
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content 'The highly valued work that everyone wants in their collection'

        # Add to second multi-membership collection of the same type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 5 for MM1' # selects the collection
          click_button 'Save changes'
        end
        # forwards to collection show page
        expect(page).to have_content(col5_mm_1.title.first)
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content 'The highly valued work that everyone wants in their collection'
      end
    end
  end

  describe 'when both collections require single membership' do
    context 'and are of different types' do
      it 'then the work is added to both collections' do
        # Add to the first single-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 1 for SM1' # selects the collection
          click_button "Save changes"
        end

        # forwards to collection show page
        expect(page).to have_content(col1_sm_1.title.first)
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content 'The highly valued work that everyone wants in their collection'

        # Add to second single-membership collection of a different type
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 3 for SM2' # selects the collection
          click_button 'Save changes'
        end
        # forwards to collection show page
        expect(page).to have_content(col3_sm_2.title.first)
        expect(page).to have_content 'Works (1)'
        expect(page).to have_content 'The highly valued work that everyone wants in their collection'
      end
    end

    context 'and are of the same type' do
      before do
        # Add to the first single-membership collection
        visit '/dashboard/my/works'
        check 'check_all'
        click_button 'Add to collection' # opens the modal
        within('div#collection-list-container') do
          choose 'Collection 1 for SM1' # selects the collection
          click_button "Save changes"
        end
      end

      context 'then the work fails to add to the second collection' do
        it 'from the dashboard->works batch add to collection' do
          # Attempt to add to second single-membership collection of the same type
          visit '/dashboard/my/works'
          check 'check_all'
          click_button 'Add to collection' # opens the modal
          within('div#collection-list-container') do
            choose 'Collection 2 for SM1' # selects the collection
            click_button 'Save changes'
          end
          # forwards to work index page and shows flash message
          expect(page).to have_link 'All Works'
          expect(page).to have_link 'Your Works'
          expect(page).to have_selector '.alert', text: 'Error: You have specified more than one of the same single-membership collection types: Single-membership 1 (Collection 1 for SM1)'
        end

        it "from the work's edit form Relationships tab" do
          skip 'Needs additional work to find and select the second collection'
          # Attempt to add to second single-membership collection of the same type
          visit edit_hyrax_generic_work_path(work)
          click_link "Relationships"
          # TODO: not sure how to find and select the correct collection

          # forwards to work index page and shows flash message
          expect(page).to have_link 'All Works'
          expect(page).to have_link 'Your Works'
          expect(page).to have_selector '.alert', text: 'Error: You have specified more than one of the same single-membership collection types: Single-membership 1 (Collection 1 for SM1)'
        end

        it "from the collection's show page Addadd to collection" do
          # Attempt to add to second single-membership collection of the same type
          visit "/dashboard/collections/#{col2_sm_1.id}"
          click_link 'Add existing works'
          check 'check_all'
          click_button 'Add to collection' # opens the modal
          within('div#collection-list-container') do
            choose 'Collection 2 for SM1' # selects the collection
            click_button 'Save changes'
          end
          # forwards to work index page and shows flash message
          # TODO: I'm not sure if this should be forwarding back to the collection show page and showing the flash message
          #       or to the works index.  Ideally, it would go back to the collection show page.
          expect(page).to have_link 'All Works'
          expect(page).to have_link 'Your Works'
          expect(page).to have_selector '.alert', text: 'Error: You have specified more than one of the same single-membership collection types: Single-membership 1 (Collection 1 for SM1)'
        end
      end
    end
  end
end
