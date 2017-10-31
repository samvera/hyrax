# coding: utf-8

RSpec.describe "Browse catalog:", type: :feature do
  let(:jill) { create(:user) }
  let(:jills_keywords) { (1..25).collect { |i| "keyword#{format('%02d', i)}" } }
  let!(:jills_work) do
    create_for_repository(:work, title: "Jill's Research", keyword: jills_keywords,
                                 user: jill, read_groups: ['public'])
  end

  let(:jack) { create(:user) }
  let(:jacks_keywords) { ['jacks_keyword'] }
  let!(:jacks_work) do
    create_for_repository(:work, title: "Jack's Research", keyword: jacks_keywords,
                                 user: jack, read_groups: ['public'])
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
      click_link "more Keywords »"
      within('.bottom') do
        click_link 'Next »'
      end

      within(".modal-body") do
        expect(page).not_to have_content 'keyword05'
        expect(page).to have_content 'keyword21'

        click_link 'keyword21'
      end

      expect(page).to have_content jills_work.title.first
      expect(page).not_to have_content jacks_work.title.first

      # TODO:  After the _generic_work.html.erb view is finished
      #
      #      click_link jills_work.title.first
      #      expect(page).to     have_content "Download"
      #      expect(page).not_to have_content "Edit"
    end
  end
end
