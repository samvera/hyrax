# frozen_string_literal: true

RSpec.describe 'batch', type: :feature, clean_repo: true, js: true do
  let(:current_user) { create(:user) }
  let!(:work1)       { create(:public_work, user: current_user) }
  let!(:work2)       { create(:public_work, user: current_user) }

  before do
    sign_in current_user
    visit '/dashboard/my/works'
    check 'check_all'
  end

  describe 'editing' do
    it 'changes the value of each field for all selected works' do
      click_on 'batch-edit'
      fill_in_batch_edit_fields_and_verify!
      work1.reload
      work2.reload
      batch_edit_fields.each do |field|
        expect(work1.send(field)).to match_array("NEW #{field}")
        expect(work2.send(field)).to match_array("NEW #{field}")
      end

      # Reload the form and verify
      visit '/dashboard/my/works'
      check 'check_all'
      find('#batch-edit').click
      expect(page).to have_content('Batch Edit Descriptions')
      batch_edit_expand("creator") do
        page.find("input#generic_work_creator[value='NEW creator']")
      end
      batch_edit_expand("contributor") do
        page.find("input#generic_work_contributor[value='NEW contributor']")
      end
      batch_edit_expand("description") do
        page.find("textarea#generic_work_description", text: 'NEW description')
      end
      batch_edit_expand("keyword") do
        page.find("input#generic_work_keyword[value='NEW keyword']")
      end
      batch_edit_expand("publisher") do
        page.find "input#generic_work_publisher[value='NEW publisher']"
      end
      batch_edit_expand("date_created") do
        page.find("input#generic_work_date_created[value='NEW date_created']")
      end
      batch_edit_expand("subject") do
        page.find("input#generic_work_subject[value='NEW subject']")
      end
      batch_edit_expand("language") do
        page.find("input#generic_work_language[value='NEW language']")
      end
      batch_edit_expand("identifier") do
        page.find("input#generic_work_identifier[value='NEW identifier']")
      end
      # batch_edit_expand("based_near")
      # expect(page).to have_css "input#generic_work_based_near[value*='NEW based_near']"
      batch_edit_expand("related_url") do
        page.find("input#generic_work_related_url[value='NEW related_url']")
      end
    end
  end

  describe 'deleting' do
    it 'destroys the selected works' do
      accept_confirm { click_button 'Delete Selected' }
      expect(page).to have_content('Batch delete complete')
      expect(GenericWork.count).to be_zero
    end
  end
end
