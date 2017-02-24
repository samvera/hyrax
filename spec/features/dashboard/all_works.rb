require 'spec_helper'

RSpec.describe "As an admin user I should be able to see all works" do
  let!(:work1) { create(:work, title: ['Testing #1']) }
  let!(:work2) { create(:work, title: ['Testing #2']) }

  before do
    sign_in create(:admin)
  end
  scenario do
    visit '/dashboard/works'
    expect(page).to have_content 'Works'
    expect(page).to have_content 'Testing #1'
    expect(page).to have_content 'Testing #2'
  end
end
