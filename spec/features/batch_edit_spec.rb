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
      find('#batch-edit').click
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
      expect(page).to have_css("input#generic_work_creator[value='NEW creator']")
      expect(page).to have_css("input#generic_work_contributor[value='NEW contributor']")
      expect(page).to have_css("textarea#generic_work_description", text: 'NEW description')
      expect(page).to have_css("input#generic_work_keyword[value='NEW keyword']")
      expect(page).to have_css("input#generic_work_publisher[value='NEW publisher']")
      expect(page).to have_css("input#generic_work_date_created[value='NEW date_created']")
      expect(page).to have_css("input#generic_work_subject[value='NEW subject']")
      expect(page).to have_css("input#generic_work_language[value='NEW language']")
      expect(page).to have_css("input#generic_work_identifier[value='NEW identifier']")
      # expect(page).to have_css("input#generic_work_based_near[value*='NEW based_near']")
      expect(page).to have_css("input#generic_work_related_url[value='NEW related_url']")
    end
  end

  describe 'deleting' do
    it 'destroys the selected works' do
      accept_confirm { click_button 'Delete Selected' }
      expect(GenericWork.count).to be_zero
    end
  end
end
