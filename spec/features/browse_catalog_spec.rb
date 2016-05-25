# coding: utf-8

describe "Browse catalog:", type: :feature do
  let!(:jills_work) do
    GenericWork.new do |work|
      work.title = ["Jill's Research"]
      (1..25).each do |i|
        work.keyword << ["keyword#{format('%02d', i)}"]
      end
      work.apply_depositor_metadata('jilluser')
      work.read_groups = ['public']
      work.save!
    end
  end

  let!(:jacks_work) do
    GenericWork.new do |work|
      work.title = ["Jack's Research"]
      work.keyword = ['jacks_keyword']
      work.apply_depositor_metadata('jackuser')
      work.read_groups = ['public']
      work.save!
    end
  end

  before do
    visit '/'
  end

  describe 'when not logged in' do
    it 'using facet pagination to browse by keywords' do
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
        expect(page).not_to have_content 'keyword05'
        expect(page).to have_content 'keyword21'

        click_link 'keyword21'
      end

      expect(page).to have_content jills_work.title.first
      expect(page).to_not have_content jacks_work.title.first

      # TODO:  After the _generic_work.html.erb view is finished
      #
      #      click_link jills_work.title.first
      #      expect(page).to     have_content "Download"
      #      expect(page).not_to have_content "Edit"
    end
  end
end
