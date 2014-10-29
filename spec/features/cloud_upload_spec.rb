require 'spec_helper'

describe "Selecting files to import from cloud providers" do
  before do
    sign_in :user
    click_link "Upload"
  end

  it "should have a Cloud file picker using browse-everything" do
    click_link "Cloud Providers"
    page.should have_content "Browse cloud files"
    page.should have_content "Submit selected files"
    page.should have_content "0 items selected"
    click_button 'Browse cloud files'
  end
end
