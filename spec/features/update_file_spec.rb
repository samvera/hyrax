require 'spec_helper'

describe "Editing attached files" do
  let(:user) { FactoryGirl.create(:user) }
  let!(:generic_file) { FactoryGirl.create(:file_with_work, user: user) }

  before do
    sign_in user
  end

  it "should update the file" do
    visit "/concern/generic_works/#{generic_file.batch.id}" 
    click_link 'Edit'

    expect(page).to have_content "Updating Attached File to \"Test title\""

    attach_file("Upload a file", fixture_file_path('files/image.png'))
    click_button "Update Attached File"
    
    expect(generic_file.reload.content.label).to eq 'image.png'
    expect(page).to have_content "The file image.png has been updated."
  end
end
