# frozen_string_literal: true

RSpec.describe 'batch', type: :feature, clean_repo: true, js: true do
  let(:current_user) { create(:user) }
  let!(:work1)       { create_for_repository(:work, :public, user: current_user) }
  let!(:work2)       { create_for_repository(:work, :public, user: current_user) }
  let(:batch_edit_fields) do
    # skipping based_near because it's a select2 field, which is hard to test via capybara
    [
      "creator", "contributor", "description", "keyword", "publisher", "date_created",
      "subject", "language", "identifier", "related_url"
    ]
  end

  before do
    sign_in current_user
    visit '/dashboard/my/works'
    check 'check_all'
  end

  describe 'editing' do
    before do
      click_on 'batch-edit'

      batch_edit_fields.each do |field_id|
        within "#form_#{field_id}" do
          find("#expand_link_#{field_id}").click
          page.find("#generic_work_#{field_id}") # Ensuring that the element is on the page before we fill it
          fill_in "generic_work_#{field_id}", with: "NEW #{field_id}"

          find("##{field_id}_save").click
          # This was `expect(page).to have_content 'Changes Saved'`, however in debugging,
          # the `have_content` check was ignoring the `within` scoping and finding
          # "Changes Saved" for other field areas
          find('.status', text: 'Changes Saved')
        end
      end
    end

    it 'changes the value of each field for all selected works' do
      # Reload the form and verify
      visit '/dashboard/my/works'
      check 'check_all'
      find('#batch-edit').click
      expect(page).to have_content('Batch Edit Descriptions')
      (batch_edit_fields - ['description']).each do |field_id|
        find("#expand_link_#{field_id}").click
        page.find("input#generic_work_#{field_id}[value='NEW #{field_id}']")
      end

      find("#expand_link_description").click
      page.find("textarea#generic_work_description", text: 'NEW description')
    end
  end

  describe 'deleting' do
    it 'destroys the selected works' do
      accept_confirm { click_button 'Delete Selected' }
      expect(Hyrax::Queries.find_all_of_model(model: ::GenericWork).size).to be_zero
    end
  end
end
