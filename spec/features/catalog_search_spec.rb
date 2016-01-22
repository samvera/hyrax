require 'spec_helper'

feature 'Catalog index page' do
  let!(:work) { create(:public_generic_work, title: ['My Work']) }
  let!(:coll) { create(:collection, :public, title: 'My Collection') }

  scenario 'Browse the catalog using filter tabs' do
    visit search_catalog_path

    # Filter on Works
    within '#type-tabs' do
      click_on 'Works'
    end

    expect(page).to have_selector('#documents .document', count: 1)
    within '#documents' do
      expect(page).to have_link 'My Work'
      expect(page).to_not have_link 'My Collection'
    end

    # Filter on Collections
    within '#type-tabs' do
      click_on 'Collections'
    end

    expect(page).to have_selector('#documents .document', count: 1)
    within '#documents' do
      expect(page).to_not have_link 'My Work'
      expect(page).to have_link 'My Collection'
    end

    # Filter on All
    within '#type-tabs' do
      click_on 'All'
    end

    expect(page).to have_selector('#documents .document', count: 2)
    within '#documents' do
      expect(page).to have_link 'My Work'
      expect(page).to have_link 'My Collection'
    end
  end
end
