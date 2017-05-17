# frozen_string_literal: true

RSpec.describe 'Batch management of works', type: :feature do
  let(:current_user) { create(:user) }
  let!(:work1)       { create(:public_work, :with_complete_metadata, user: current_user) }
  let!(:work2)       { create(:public_work, :with_complete_metadata, user: current_user) }

  before do
    sign_in_with_named_js(:batch_edit, current_user, disable_animations: true)
    visit '/dashboard/my/works'
    expect(page).not_to have_content 'You need to sign in'
  end

  context 'when editing and viewing multiple works' do
    before do
      check 'check_all'
      click_on 'batch-edit'
    end

    it 'edits a field and displays the changes', js: true do
      batch_edit_fields.each do |field|
        fill_in_batch_edit_field(field, with: "Updated batch #{field}")
      end
      work1.reload
      work2.reload
      batch_edit_fields.each do |field|
        expect(work1.send(field)).to contain_exactly("Updated batch #{field}")
        expect(work2.send(field)).to contain_exactly("Updated batch #{field}")
      end
    end

    it "displays the field's existing value" do
      within("textarea#batch_edit_item_description") do
        expect(page).to have_content("descriptiondescription")
      end
      expect(page).to have_css "input#batch_edit_item_contributor[value*='contributorcontributor']"
      expect(page).to have_css "input#batch_edit_item_keyword[value*='tagtag']"
      expect(page).to have_css "input#batch_edit_item_based_near[value*='based_nearbased_near']"
      expect(page).to have_css "input#batch_edit_item_language[value*='languagelanguage']"
      expect(page).to have_css "input#batch_edit_item_creator[value*='creatorcreator']"
      expect(page).to have_css "input#batch_edit_item_publisher[value*='publisherpublisher']"
      expect(page).to have_css "input#batch_edit_item_subject[value*='subjectsubject']"
      expect(page).to have_css "input#batch_edit_item_related_url[value*='http://example.org/TheRelatedURLLink/']"
      expect(page).to have_no_checked_field("Private")
      # expect(page).to have_content(I18n.t('scholarsphere.batch_edit.permissions_warning'))
      expect(page).to have_content('foo warning')
    end
  end

  context "when selecting multiple works for deletion", js: true do
    subject { GenericWork.count }
    before do
      check "check_all"
      click_button "Delete Selected"
    end
    it { is_expected.to be_zero }
  end
end
