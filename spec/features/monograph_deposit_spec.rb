# frozen_string_literal: true
RSpec.describe 'Creating a new Monograph (Valkyrie work)', :js, :workflow, :clean_repo do
  let(:user) { FactoryBot.create(:user) }

  before do
    Hyrax::EnsureWellFormedAdminSetService.call
    FactoryBot
      .create(:permission_template_access,
              :deposit,
              permission_template: FactoryBot.create(:permission_template, with_admin_set: true, with_active_workflow: true),
              agent_type: 'user',
              agent_id: user.user_key)
  end

  it 'creates the work' do
    sign_in user
    click_link 'Works'
    find('#add-new-work-button').click

    choose "payload_concern", option: "Monograph"
    click_button 'Create work'

    click_link "Files" # switch tab
    expect(page).to have_content "Add files"
    within('div#add-files') do
      attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
    end

    click_link "Descriptions" # switch tab
    # form fields for basic metadata
    fill_in('Title', with: 'Monograph Work (created by test)')
    click_on("Additional fields")
    fill_in('Abstract', with: 'A formal abstract.')
    fill_in('Access Right', with: 'Open Access')
    fill_in('Creator', with: 'Tove Jansson')
    # end basic metadata
    fill_in('Record info', with: 'some details about the record') # required in monograph schema

    choose('monograph_visibility_open')
    check('agreement')

    click_on('Save')

    monograph_id = current_url.split('/').last.split('?').first
    monograph = Hyrax.query_service.find_by(id: monograph_id)

    expect(monograph)
      .to have_attributes(title: contain_exactly('Monograph Work (created by test)'),
                          abstract: contain_exactly('A formal abstract.'),
                          access_right: contain_exactly('Open Access'),
                          creator: contain_exactly('Tove Jansson'),
                          record_info: 'some details about the record')

    expect(page).to have_content('Monograph Work (created by test)')
    expect(page).to have_content('Tove Jansson')
  end
end
