# frozen_string_literal: true
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
      expect(rendered).to have_field('locale', type: :hidden, with: 'en')
    end

    it 'labels both date fields' do
      expect(rendered).to have_field('Start', type: 'date')
      expect(rendered).to have_field('End [defaults to now]', type: 'date')
    end

    it 'explains the date filter once' do
      expect(rendered.scan('Statistics in this section are filtered').size).to eq 1
    end

    it 'keeps the top data explanation out of the heading outline' do
      expect(rendered).to have_selector('p', text: 'Statistics in this section shows the top 5')
      expect(rendered).not_to have_selector('h3', text: 'Statistics in this section shows')
    end

    it 'gives the page a heading' do
      expect(view.content_for(:page_header)).to have_selector('h1', text: 'Statistics')
    end
  end

  context 'in another locale' do
    before do
      allow(presenter).to receive(:active_users).and_return([])
      I18n.with_locale(:de) { render }
    end

    it 'translates the date form' do
      expect(rendered).to have_field('Beginn', type: 'date')
      expect(rendered).to have_button('Statistik laden')
      expect(rendered).to have_field('locale', type: :hidden, with: 'de')
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
