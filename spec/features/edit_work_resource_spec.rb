# frozen_string_literal: true

RSpec.describe 'Editing an existing Hyrax::Work Resource', :js, :workflow, :feature do
  let(:user) { FactoryBot.create(:user) }

  let(:work) do
    FactoryBot.valkyrie_create(:comet_in_moominland, edit_users: [user])
  end

  before do
    work # create it
    sign_in user
  end

  scenario 'edit the work' do
    visit edit_hyrax_monograph_path(work)

    fill_in('Title', with: 'Updated by Edit Work Spec')

    choose('monograph_visibility_open')
    check('agreement')

    click_on('Save')

    expect(page).to have_content 'Updated by Edit Work Spec'

    within(".work-title-wrapper") do
      expect(page).to have_content('Public')
    end
  end
end
