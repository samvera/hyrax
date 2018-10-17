RSpec.describe "hyrax/admin/stats/show.html.erb", type: :view do
  let(:presenter) do
    Hyrax::AdminStatsPresenter.new({}, 5)
  end

  before do
    assign(:presenter, presenter)
    allow(presenter).to receive(:top_formats).and_return([])
    allow(presenter).to receive(:works_count).and_return(total: 0)
    allow(presenter).to receive(:depositors).and_return([])
  end

  context 'locales' do
    before do
      allow(presenter).to receive(:active_users).and_return([])
      render
    end
    it 'includes a default locale hidden input' do
      expect(rendered).to have_selector 'input', exact: 'en'
    end
  end

  context "default depositors" do
    let(:top_5_active_users) do
      (1..5).map { |i| double(label: i.to_s, value: i) }
    end

    before do
      allow(presenter).to receive(:active_users).and_return(top_5_active_users)
      render
    end
    it "shows top 5 depositors and option to view more" do
      expect(rendered).to have_content("(top 5)")
      expect(rendered).to have_link("View top 20", href: "/admin/stats?limit=20")
    end
  end

  context "top 20 depositors" do
    let(:top_20_active_users) do
      (1..20).map { |i| double(label: i.to_s, value: i) }
    end

    before do
      allow(presenter).to receive(:active_users).and_return(top_20_active_users)
      allow(presenter).to receive(:limit).and_return(20)
      render
    end

    it "shows top 20 depositors, without an option to view more" do
      expect(rendered).to have_content("(top 20)")
      expect(rendered).not_to have_content("View top 20")
    end
  end
end
