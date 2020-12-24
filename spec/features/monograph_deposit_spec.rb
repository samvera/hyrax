# frozen_string_literal: true
RSpec.describe 'Creating a new Monograph (Valkyrie work)', :js, :workflow, :clean_repo do
  let(:user) { FactoryBot.create(:user) }

  before do
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
    click_link "Add new work"

    choose "payload_concern", option: "Monograph"
    click_button 'Create work'

    click_link "Files" # switch tab
    expect(page).to have_content "Add files"
    within('div#add-files') do
      attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
    end

    click_link "Descriptions" # switch tab
    fill_in('Title', with: 'Monograph Work')
    fill_in('Creator', with: 'Tove Jansson')
    fill_in('Record info', with: 'some details about the record')

    choose('monograph_visibility_open')
    check('agreement')

    click_on('Save')

    monograph_id = current_url.split('/').last.split('?').first
    monograph = Hyrax.query_service.find_by(id: monograph_id)

    expect(monograph)
      .to have_attributes(title: contain_exactly('Monograph Work'),
                          creator: contain_exactly('Tove Jansson'),
                          record_info: 'some details about the record')
  end
end
