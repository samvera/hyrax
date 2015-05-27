require 'spec_helper'

describe "Creating a new Work" do
  let(:user) { FactoryGirl.create(:user) }
  # let!(:work) { FactoryGirl.create(:work, user: user) }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    s2 = double('resque message')
    expect(CharacterizeJob).to receive(:new).and_return(s2)
    expect(Sufia.queue).to receive(:push).with(s2).once
  end

  it "should create the work and allow you to attach a file" do
    visit "/concern/generic_works/new"


    # within("form.new_generic_file") do
    #   attach_file("Upload a file", fixture_file_path('files/image.png'))
    #   click_button "Attach to Generic Work"
    # end
    within("form.new_generic_work") do
      fill_in("Title", with: 'My Test Work')
      attach_file("Upload a file", fixture_file_path('files/image.png'))
      choose("visibility_open")
      click_on("Create Generic work")
    end

    within '.related_files' do
      expect(page).to have_link "image.png"
    end
  end
end

