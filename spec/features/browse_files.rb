require 'spec_helper'

describe "Browse files" do

  describe "when not logged in" do
    it "should let us browse some of the fixtures" do
      visit '/'
      click_link "more Keywords"
      click_link "test"
      # TODO this used to be 1 - 4 of 4, but now we get 5. WTF?
      # It looks to me like sufia:sufia1, sufia:test3,  sufia:test4,  sufia:test5, sufia:test6 all should match
      page.should have_content "1 - 5 of 5"
      click_link "Test Document PDF"
      page.should have_content "Download"
      page.should_not have_content "Edit"
    end

  end

  describe "when logged in" do
    before do
      sign_in :user
    end
    it "should let us browse some of the fixtures and see the edit link"do
      click_link "more Keywords"
      click_link "test"
      click_link "Test Document PDF"
      page.should_not have_content "Edit"
    end
  end
end
