# frozen_string_literal: true
RSpec.describe "Browse catalog:", type: :feature, clean_repo: true do
  let!(:jills_work) do
    valkyrie_create(:monograph,
                  title: ["Jill's Research"],
                  keyword: (1..25).to_a.map { |i| "keyword#{format('%02d', i)}" },
                  read_groups: ['public'])
  end

  let!(:jacks_work) do
    valkyrie_create(:monograph,
                  title: ["Jack's Research"],
                  keyword: ['jacks_keyword'],
                  read_groups: ['public'])
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

      click_button "Keyword"
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
