require 'spec_helper'

feature 'Add an attached file' do
  let(:user) { create(:user) }
  let!(:work) { create(:work, user: user) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
  end

  before do
    sign_in user
    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
    allow_any_instance_of(CurationConcerns::Actors::FileSetActor).to receive(:acquire_lock_for).and_yield
  end

  it 'updates the file' do
    visit "/concern/generic_works/#{work.id}"
    click_link 'Attach a File'

    within('form.new_file_set') do
      fill_in('Title', with: 'image.png')
      attach_file('Upload a file', fixture_file_path('files/image.png'))
      click_on('Attach to Generic Work')
    end

    visit "/concern/generic_works/#{work.id}"
    within '.related_files' do
      expect(page).to have_link 'image.png'
    end
  end
end
