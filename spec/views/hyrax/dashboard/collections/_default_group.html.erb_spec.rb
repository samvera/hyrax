# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_default_group.html.erb', type: :view do
  let(:ability) { double }

  before do
    allow(view).to receive(:docs).and_return([])
    allow(view).to receive(:current_ability).and_return(ability)
    stub_template 'hyrax/my/_list_collections.html.erb' => 'collection row'
  end

  context 'Managed Collections' do
    before do
      allow(ability).to receive(:admin?).and_return(false)
      render
    end

    it 'shows collection table headings' do
      expect(rendered).to have_text('Title')
      expect(rendered).to have_text('Access')
      expect(rendered).to have_text('Type')
      expect(rendered).to have_text('Visibility')
      expect(rendered).to have_text('Items')
      expect(rendered).to have_text('Last modified')
      expect(rendered).to have_text('Actions')
    end
  end

  context 'All Collections' do
    before do
      allow(ability).to receive(:admin?).and_return(true)
      render
    end

    it "doesn't show access" do
      expect(rendered).to have_text('Title')
      expect(rendered).not_to have_text('Access')
      expect(rendered).to have_text('Type')
      expect(rendered).to have_text('Visibility')
      expect(rendered).to have_text('Items')
      expect(rendered).to have_text('Last modified')
      expect(rendered).to have_text('Actions')
    end
  end
end
