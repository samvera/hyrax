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

    # Wait for FieldManager JS to fully initialize the title field.
    # FieldManager adds the 'managed' class to the form-group and appends
    # "Add another" controls. Both editMetadata.js and the Editor's init()
    # can trigger FieldManager initialization; waiting for the 'managed'
    # class ensures all DOM modifications are complete before we interact.
    title_group = find('.multi_value.form-group.managed', text: 'Title', wait: 10)

    fill_in('Title', with: 'Updated by Edit Work Spec')

    # Guard against late JS clearing the value (e.g. a second onLoad pass).
    # If the value was cleared, set it directly via JavaScript.
    unless page.has_field?('Title', with: 'Updated by Edit Work Spec', wait: 1)
      title_input = title_group.find('input.multi-text-field')
      page.execute_script("arguments[0].value = arguments[1]", title_input.native, 'Updated by Edit Work Spec')
    end

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
