# frozen_string_literal: true
# https://github.com/samvera/hyrax/issues/5969
RSpec.describe "As an regular user I should be able to filter works and add them to a preselected collection", :clean_repo do
  let(:user) { create(:user) }
  let!(:work1) { valkyrie_create(:monograph, title: ['Testing Work'], admin_set_id: adminset.id, depositor: user.user_key) }
  let!(:work2) { valkyrie_create(:monograph, title: ['Samvera Document'], admin_set_id: adminset.id, depositor: user.user_key) }
  let(:collection_type) { create(:collection_type, creator_user: user) }
  let(:collection) { valkyrie_create(:hyrax_collection, :public, user: user, collection_type_gid: collection_type.to_global_id) }
  let(:adminset) { valkyrie_create(:hyrax_admin_set) }

  before do
    sign_in user
  end
  it do
    visit "/dashboard/my/works?add_works_to_collection=#{collection.id}&add_works_to_collection_label[]=Special+Test+Collection"
    expect(page).to have_content 'Works'
    expect(page).to have_content 'Testing Work'
    expect(page).to have_content 'Samvera Document'

    # Verify add to collection button works without a filter
    first('.batch_document_selector').click

    click_button("Add to collection")

    expect(find('#member_of_collection_label')['value']).to eq "Special Test Collection"
    expect(page).to have_button 'Save changes'
    find('#collection-list-container button.btn').click # click on the close button for the modal

    # Verify add to collection button works with a filter
    fill_in('search-field-header', with: "work")
    click_button("Go")

    expect(page).to have_content 'Testing Work'
    expect(page).not_to have_content 'Samvera Document'

    first('.batch_document_selector').click

    click_button("Add to collection")

    expect(find('#member_of_collection_label')['value']).to eq "Special Test Collection"
    expect(page).to have_button 'Save changes'
  end
end
