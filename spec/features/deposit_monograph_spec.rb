# frozen_string_literal: true

# end to end tests for creating a Valkyrie native work with an generic Valkyrie adapter
RSpec.describe 'Creating a new Monograph work', :js, :workflow, valkyrie_adapter: :test_adapter do
  let(:user) { create(:user) }

  before { sign_in user }

  it 'creates the work' do
    click_link 'Works'
    click_link 'Add new work'
    choose 'payload_concern', option: 'Monograph'
    click_button 'Create work'


    click_link 'Files'
    expect(page).to have_content 'Add files'
    within('div#add-files') do
      attach_file('files[]', "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
    end

    click_link 'Descriptions'
    fill_in('Title', with: 'Comet in Moominland')
    fill_in('Creator', with: 'Jansson, Tove')
    select('In Copyright', from: 'Rights statement')

    choose('monograph_visibility_open')
    check('agreement')

    click_on('Save')
  end
end
