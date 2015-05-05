require 'spec_helper'

describe "Add an attached file" do
  let(:user) { FactoryGirl.create(:user) }
  let!(:work) { FactoryGirl.create(:work, user: user) }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    s2 = double('resque message')
    expect(CharacterizeJob).to receive(:new).and_return(s2)
    expect(Sufia.queue).to receive(:push).with(s2).once
  end

  it "should update the file" do
    visit "/concern/generic_works/#{work.id}"
    click_link 'Attach a File'

    # within("form.new_generic_file") do
    #   attach_file("Upload a file", fixture_file_path('files/image.png'))
    #   click_button "Attach to Generic Work"
    # end
    within("form.new_generic_file") do
      fill_in("Title", with: 'image.png')
      attach_file("Upload a file", fixture_file_path('files/image.png'))
      click_on("Attach to Generic Work")
    end

    within '.related_files' do
      expect(page).to have_link "image.png"
    end
  end
end

