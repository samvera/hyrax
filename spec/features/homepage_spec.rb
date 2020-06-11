# frozen_string_literal: true
RSpec.describe "The homepage", :clean_repo do
  let(:work1) { create(:work, :public, title: ["Work 1"], date_uploaded: (DateTime.current - 1.day)) }
  let(:work2) { create(:work, :public, title: ["Work 2"], date_uploaded: (DateTime.current - 1.year)) }

  before do
    create(:featured_work, work_id: work1.id)
  end

  it 'shows featured works' do
    visit root_path
    expect(page).to have_link work1.title.first
  end

  it 'shows recently uploaded' do
    visit root_path
    click_link("Recently Uploaded")
    within '#recently_uploaded' do
      # Expect to see the one with "date uploaded" of yesterday
      expect(page).to have_link work1.title.first
      # Do not expect to see the one with "date uploaded" of last year.
      expect(page).not_to have_link work2.title.first
      # Expect the system create of work2 to be later than that of work1.
      # This helps verify that 'recently uploaded' is looking at
      # 'date_uploaded_dtsi'  and not 'system_create_dtsi'.
      expect(DateTime.parse(work2.to_solr['system_create_dtsi']).getlocal).to be >= DateTime.parse(work1.to_solr['system_create_dtsi']).getlocal
    end
  end

  context "as an admin" do
    let(:user) { create(:admin) }

    before do
      sign_in user
    end

    it 'shows featured works that I can sort' do
      visit root_path
      within '.dd-item' do
        expect(page).to have_link work1.title.first
      end
    end
  end
end
