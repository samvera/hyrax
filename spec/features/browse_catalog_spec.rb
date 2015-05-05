require 'spec_helper'

describe "Browse catalog:", :type => :feature do

  let!(:jills_work) {
    Sufia::Works::GenericWork.new.tap do |work|
      work.title = ["Jill's Research"]
      (1..25).each do |i|
        work.tag << ["tag#{sprintf('%02d', i)}"]
      end
      work.apply_depositor_metadata('jilluser')
      work.read_groups = ['public']
      work.save!
    end
  }

  let!(:jacks_work) {
    Sufia::Works::GenericWork.new.tap do |work|
    work.title = ["Jack's Research"]
    work.tag = ['jacks_tag']
    work.apply_depositor_metadata('jackuser')
    work.read_groups = ['public']
    work.save!
    end
  }

  before do
    visit '/'
  end

  describe 'when not logged in' do
    it 'using facet pagination to browse by tags' do
      click_button "search-submit-header"

      expect(page).to have_content 'Search Results'
      expect(page).to have_content jills_work.title.first
      expect(page).to have_content jacks_work.title.first

      click_link "Keyword"
      click_link "more Keywords»"
      within('.bottom') do
        click_link 'Next »'
      end

      within(".modal-body") do
        expect(page).not_to have_content 'tag05'
        expect(page).to     have_content 'tag21'

        click_link 'tag21'
      end

      expect(page).to     have_content jills_work.title.first
      expect(page).to_not have_content jacks_work.title.first

# TODO:  After the _generic_work.html.erb view is finished
#
#      click_link jills_work.title.first
#      expect(page).to     have_content "Download"
#      expect(page).not_to have_content "Edit"
    end
  end

end
