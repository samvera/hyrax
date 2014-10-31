require 'spec_helper'

describe "Selecting files to import from cloud providers", :type => :feature do
  before do
    sign_in :user
    click_link "Upload"
  end

  it "should have a Cloud file picker using browse-everything" do
    click_link "Cloud Providers"
    expect(page).to have_content "Browse cloud files"
    expect(page).to have_content "Submit selected files"
    expect(page).to have_content "0 items selected"
    click_button 'Browse cloud files'
  end
end
