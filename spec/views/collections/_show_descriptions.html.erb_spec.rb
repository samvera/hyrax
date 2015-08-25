require 'spec_helper'

describe 'collections/_show_descriptions.html.erb', type: :view do
  context 'displaying a custom collection' do
    let(:collection_size) { 123_456_678 }
    let(:collection) do
      mock_model(Collection,
                 resource_type: [], creator: [], contributor: [], tag: [],
                 description: '', title: 'hmm',
                 rights: [], publisher: [], date_created: ['2000-01-01'], subject: [],
                 language: [], identifier: [], based_near: [], related_url: [],
                 members: ['foo', 'bar']
                )
    end
    before do
      assign(:presenter, presenter)
      allow(Sufia::CollectionSizeService).to receive(:run).and_return(collection_size)
    end

    let(:presenter) { Sufia::CollectionPresenter.new(collection) }

    it "draws the metadata fields for collection" do
      render
      expect(rendered).to have_content 'Date Created'
      expect(rendered).to include('itemprop="dateCreated"')
      expect(rendered).to have_content 'Total Items'
      expect(rendered).to have_content '2'
      expect(rendered).to have_content 'Size'
      expect(rendered).to have_content '118 MB'
    end
  end
end
