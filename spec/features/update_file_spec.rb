require 'spec_helper'

describe "Editing attached files" do
  let(:user) { FactoryGirl.create(:user) }
  let!(:generic_file) { FactoryGirl.create(:file_with_work, user: user) }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    s2 = double('resque message')
    expect(CharacterizeJob).to receive(:new).and_return(s2)
    expect(Sufia.queue).to receive(:push).with(s2).once
  end

  it "should update the file" do
    visit "/concern/generic_works/#{generic_file.batch.id}"
    click_link 'Edit'

    expect(page).to have_content "Updating Attached File to \"Test title\""

    attach_file("Upload a file", fixture_file_path('files/image.png'))
    click_button "Update Attached File"

    expect(page).to have_content "The file testfile has been updated."
    generic_file.reload
    expect(generic_file.content.original_name).to eq 'image.png'
    expect(generic_file.content.mime_type).to eq 'image/png'
  end
end
