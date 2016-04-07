require 'spec_helper'

describe CurationConcerns::CollectionsHelper do
  describe '#link_to_select_collection' do
    let(:collection) { double(id: '123') }
    let(:collectible) { double(id: '456', human_readable_type: 'Generic Work', to_param: '456') }
    before do
      assign(:collection, collection)
    end
    subject { helper.link_to_select_collection(collectible) }

    it 'has a link that pops up a modal' do
      expect(subject).to have_selector 'a[data-toggle=modal][data-target="#456-modal"]'
      expect(subject).to have_link 'Add to a Collection', href: '#'
    end
  end

  describe '#link_to_remove_from_collection' do
    let(:collection) { double(id: '123') }
    let(:collectible) { double(id: '456') }
    before do
      assign(:collection, collection)
    end
    subject { helper.link_to_remove_from_collection(collectible) }

    it 'has a form that routes to remove the collectible' do
      expect(subject).to have_selector 'a[data-method=put]'
      expect(subject).to have_link 'Remove From Collection',
                                   href: collection_path('123', collection: { members: 'remove' },
                                                                batch_document_ids: ['456'])
    end
  end

  describe '#collection_options_for_select' do
    let(:user) { create(:user) }
    let(:collection2) { double(id: '02870w10j') }
    let(:doc1) { { "id" => "k930bx31t", "title_tesim" => ["One"] } }
    let(:doc2) { { "id" => "02870w10j", "title_tesim" => ["Two"] } }
    let(:doc3) { { "id" => "z029p500w", "title_tesim" => ["Three"] } }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(ActiveFedora::SolrService).to receive(:query)
        .with("_query_:\"{!field f=has_model_ssim}Collection\"",
              fl: 'title_tesim id', rows: 1000)
        .and_return([doc1, doc2, doc3])
    end

    subject { helper.collection_options_for_select(collection2) }

    it 'excludes the passed in collection' do
      expect(subject).to eq "<option value=\"#{doc1['id']}\">One</option>\n<option value=\"#{doc3['id']}\">Three</option>"
    end

    context "when one of the documents doesn't have title_tesim" do
      let(:doc1) { { "id" => "k930bx31t" } }
      it 'puts the collections without titles last' do
        expect(subject).to eq "<option value=\"#{doc3['id']}\">Three</option>\n<option value=\"#{doc1['id']}\"></option>"
      end
    end
  end
end
