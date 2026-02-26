# frozen_string_literal: true
RSpec.describe 'Bulkrax', :js, :workflow, :clean_repo, skip: !Hyrax.config.disable_wings,
               perform_enqueued: true do
  let(:user) { create(:admin) }

  before do
    Hyrax::EnsureWellFormedAdminSetService.call
    sign_in user
  end

  it 'imports CSV' do
    visit '/importers/new'
    fill_in 'Name', with: 'Test CSV Importer'
    select 'Default Admin Set', from: 'Administrative Set'
    select 'CSV - Comma Separated Values', from: 'Parser'
    expect(page).to have_content('Add CSV or ZIP File to Import')
    select 'Copyright Undetermined', from: 'Rights statement'

    choose 'Upload a File'
    click_on 'Add Files'
    attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/bulkrax/test_image.csv", visible: false)
    expect(page).to have_content('test_image.csv')

    click_on 'Add Cloud Files'
    click_on 'bulkrax'
    click_on 'octothorpe-1.ptif.tiff'
    click_on 'octothorpe-2.ptif.tiff'
    expect(page).to have_content('2 files selected')
    click_on 'Submit'

    expect(page).to have_content('Cloud Files Added')
    click_on 'Create and Import'

    expect(page).to have_content('Importer was successfully created and import has been queued.')
    expect(page).to have_content('Test CSV Importer')

    visit '/catalog'
    expect(page).to have_content('A Test Work')
    expect(page).to have_content('A Test Collection')

    click_link 'A Test Work', match: :first
    expect(page).to have_content('octothorpe-1.ptif.tiff')
    expect(page).to have_content('octothorpe-2.ptif.tiff')
    expect(page).to have_content('A Test Collection')
  end
end
