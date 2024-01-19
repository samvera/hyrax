# frozen_string_literal: true

RSpec.describe 'Editing an existing Hyrax::Work Resource', :js, :workflow, :feature, :clean_repo do
  let(:user) { FactoryBot.create(:user) }

  let(:work) do
    FactoryBot.valkyrie_create(:comet_in_moominland, :with_admin_set, admin_set: old_admin_set, edit_users: [user])
  end
  let(:default_admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }
  let(:old_admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, title: ['Old Admin Set'], user: user) }
  let(:new_admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, title: ['New Admin Set'], user: user) }

  before do
    default_admin_set
    new_admin_set
    work # create it
    sign_in user
  end

  scenario 'edit the work' do
    visit edit_hyrax_monograph_path(work)

    fill_in('Title', with: 'Updated by Edit Work Spec')

    click_link('Relationships')
    expect(page).to have_select('Administrative Set', selected: 'Old Admin Set')
    select('New Admin Set', from: 'Administrative Set')

    choose('monograph_visibility_open')
    check('agreement')

    click_on('Save')

    expect(page).to have_content 'Updated by Edit Work Spec'

    within(".work-title-wrapper") do
      expect(page).to have_content('Public')
    end

    expect(page).to have_content('New Admin Set')
  end
end
