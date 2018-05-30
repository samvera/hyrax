RSpec.describe "As an admin user I should be able to see all works", :clean_repo do
  let!(:work1) { create(:work, title: ['Testing #1'], admin_set: adminset, member_of_collections: [collection]) }
  let!(:work2) { create(:work, title: ['Testing #2'], admin_set: adminset, member_of_collections: [collection]) }
  let(:collection) { build(:collection_lw, with_solr_document: true) }
  let(:adminset) { create(:admin_set) }

  before do
    sign_in create(:admin)
  end
  it do
    visit '/dashboard/works'
    expect(page).to have_content 'Works'
    expect(page).to have_content 'Testing #1'
    expect(page).to have_content 'Testing #2'

    # check for filters
    expect(page).to have_button('Collection')
    expect(page).to have_link(collection.title.first, class: 'facet_select')
    expect(page).to have_button('Admin Set')
    expect(page).to have_link(adminset.title.first, class: 'facet_select')
    expect(page).to have_content("2 works in the repository")
  end
end
