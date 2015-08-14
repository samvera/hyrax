require 'spec_helper'

describe 'Editing attached files' do
  let(:user) { create(:user) }
  let!(:parent) { create(:work_with_one_file, user: user) }
  let!(:generic_file) { parent.generic_files.first }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    s2 = double('resque message')
    expect(CharacterizeJob).to receive(:new).and_return(s2)
    expect(CurationConcerns.queue).to receive(:push).with(s2).once
  end

  it 'updates the file' do
    visit "/concern/generic_works/#{parent.id}"
    click_link 'Edit'
    expect(page).to have_content "Updating Attached File to \"Test title\""

    attach_file('Upload a file', fixture_file_path('files/image.png'))
    click_button 'Update Attached File'

    expect(page).to have_content 'The file A Contained Generic File has been updated.'

    # TODO: this stuff belongs in an Actor or Controller test:
    generic_file.reload
    expect(generic_file.original_file.original_name).to eq 'image.png'
    expect(generic_file.original_file.mime_type).to eq 'image/png'
  end
end
