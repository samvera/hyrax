# coding: utf-8

RSpec.describe "Browse catalog:", type: :feature do
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

      page.assert_text 'Search Results'
      page.assert_text jills_work.title.first
      page.assert_text jacks_work.title.first

      click_link "Keyword"
      click_link "more Keywords »"
      within('.bottom') do
        click_link 'Next »'
      end

      within(".modal-body") do
        page.assert_no_text 'keyword05'
        page.assert_text 'keyword21'

        click_link 'keyword21'
      end

      page.assert_text jills_work.title.first
      page.assert_no_text jacks_work.title.first

      # TODO:  After the _generic_work.html.erb view is finished
      #
      #      click_link jills_work.title.first
      #      expect(page).to     have_content "Download"
      #      expect(page).not_assert_text "Edit"
    end
  end
end
