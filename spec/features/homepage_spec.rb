require 'spec_helper'

RSpec.feature "The homepage" do
  let(:work1) { create(:work, :public, title: ['Work 1']) }
  before do
    create(:featured_work, work_id: work1.id)
  end

  scenario do
    visit root_path

    # It shows featured works
    expect(page).to have_link "Work 1"
  end

  context "as an admin" do
    let(:user) { create(:admin) }
    before do
      sign_in user
      visit root_path
    end

    scenario do
      # It shows featured works that I can sort
      within '.dd-item' do
        expect(page).to have_link "Work 1"
      end
    end
  end
end
