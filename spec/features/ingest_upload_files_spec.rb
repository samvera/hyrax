require 'spec_helper'

describe "Uploading files via web form", :js do
  include ActiveJob::TestHelper
  before do
    Capybara.default_max_wait_time = 60
    sign_in :user
    click_link "Upload"
  end

  it "puts them in the repository" do
    expect(page).to have_content "Select files"
    expect(page).to have_content "Start upload"
    expect(page).to have_content "Cancel upload"

    attach_file("file_set[files][]", File.dirname(__FILE__) + "/../../spec/fixtures/image.jp2", visible: false)
    attach_file("file_set[files][]", File.dirname(__FILE__) + "/../../spec/fixtures/jp2_fits.xml", visible: false)
    expect(page).to have_css("button#main_upload_start[disabled]")
    find('#main_upload_start_span').hover
    expect(page).to have_content "Please accept Deposit Agreement before you can upload."

    check 'terms_of_service'

    click_button "Start upload"

    # This will take awhile because it's waiting for all files to upload and
    # a redirect to the upload_set edit page.
    expect(page).to have_content "Individual Titles"

    expect(page).to have_css("input[type='text'][value='image.jp2']")
    expect(page).to have_css("input[type='text'][value='jp2_fits.xml']")

    fill_in 'upload_set_creator', with: 'Gaius Julius Caesar IV'

    click_button "Save"

    expect(page).to have_content "Your files are being processed by Repository in the background."
  end
end
