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
      batch_edit_fields.each do |f|
        if f == "resource_type"
          select_batch_edit_field(f, 'Book')
        else
          fill_in_batch_edit_field(f)
        end
      end
      batch_edit_fields.each do |f|
        fill_in_batch_edit_field_and_verify(f)
      end
      work1.reload
      work2.reload
      expect(work1.creator).to eq ['NEW creator']
      expect(work1.contributor).to eq ['NEW contributor']
      expect(work1.description).to eq ['NEW description']
      expect(work1.keyword).to eq ['NEW keyword']
      expect(work1.publisher).to eq ['NEW publisher']
      expect(work1.date_created).to eq ['NEW date_created']
      expect(work1.subject).to eq ['NEW subject']
      expect(work1.language).to eq ['NEW language']
      expect(work1.identifier).to eq ['NEW identifier']
      # expect(work1.based_near).to eq ['NEW based_near']
      expect(work1.related_url).to eq ['NEW related_url']
      expect(work1.resource_type).to eq ['Book']
      expect(work2.creator).to eq ['NEW creator']
      expect(work2.contributor).to eq ['NEW contributor']
      expect(work2.description).to eq ['NEW description']
      expect(work2.keyword).to eq ['NEW keyword']
      expect(work2.publisher).to eq ['NEW publisher']
      expect(work2.date_created).to eq ['NEW date_created']
      expect(work2.subject).to eq ['NEW subject']
      expect(work2.language).to eq ['NEW language']
      expect(work2.identifier).to eq ['NEW identifier']
      # expect(work2.based_near).to eq ['NEW based_near']
      expect(work2.related_url).to eq ['NEW related_url']
      expect(work2.resource_type).to eq ['Book']

      # Reload the form and verify
      visit '/dashboard/my/works'
      check 'check_all'
      click_on 'batch-edit'
      expect(page).to have_content('Batch Edit Descriptions')
      batch_edit_expand("creator")
      expect(page).to have_css "input#generic_work_creator[value*='NEW creator']"
      batch_edit_expand("contributor")
      expect(page).to have_css "input#generic_work_contributor[value*='NEW contributor']"
      batch_edit_expand("description")
      expect(page).to have_css "textarea#generic_work_description", text: 'NEW description'
      batch_edit_expand("keyword")
      expect(page).to have_css "input#generic_work_keyword[value*='NEW keyword']"
      batch_edit_expand("publisher")
      expect(page).to have_css "input#generic_work_publisher[value*='NEW publisher']"
      batch_edit_expand("date_created")
      expect(page).to have_css "input#generic_work_date_created[value*='NEW date_created']"
      batch_edit_expand("subject")
      expect(page).to have_css "input#generic_work_subject[value*='NEW subject']"
      batch_edit_expand("language")
      expect(page).to have_css "input#generic_work_language[value*='NEW language']"
      batch_edit_expand("identifier")
      expect(page).to have_css "input#generic_work_identifier[value*='NEW identifier']"
      # batch_edit_expand("based_near")
      # expect(page).to have_css "input#generic_work_based_near[value*='NEW based_near']"
      batch_edit_expand("related_url")
      expect(page).to have_css "input#generic_work_related_url[value*='NEW related_url']"
      batch_edit_expand("resource_type")
      expect(page).to have_select "generic_work_resource_type", selected: 'Book'
    end
  end

  describe 'deleting' do
    it 'destroys the selected works' do
      accept_confirm { click_button 'Delete Selected' }
      expect(GenericWork.count).to be_zero
    end
  end
end
