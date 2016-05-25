describe "Selecting files to import from cloud providers", type: :feature do
  before do
    sign_in :user
  end

  it "has a Cloud file picker using browse-everything" do
    skip "TBD in https://github.com/projecthydra/sufia/issues/1699"
    click_link "Create Work"
    click_link "Cloud Providers"
    expect(page).to have_content "Browse cloud files"
    expect(page).to have_content "Submit selected files"
    expect(page).to have_content "0 items selected"
    click_button 'Browse cloud files'
  end
end
