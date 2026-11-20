# frozen_string_literal: true
RSpec.describe 'hyrax/collections/_collection_description.erb', type: :view do
  let(:presenter) { double('presenter', description: descriptions) }

  before do
    assign(:presenter, presenter)
  end

  context 'when description contains a URL' do
    let(:descriptions) { ['Visit https://example.com for more information.'] }

    it 'renders the URL as a link that opens in a new tab' do
      render 'hyrax/collections/collection_description', presenter: presenter
      expect(rendered).to have_selector('a[href="https://example.com"][target="_blank"][rel="noopener noreferrer"]')
    end
  end

  context 'when description contains no URLs' do
    let(:descriptions) { ['A plain text description with no links.'] }

    it 'renders the description as plain text' do
      render 'hyrax/collections/collection_description', presenter: presenter
      expect(rendered).to include('A plain text description with no links.')
      expect(rendered).not_to have_selector('a')
    end
  end
end
