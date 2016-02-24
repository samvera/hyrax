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
                                   href: collections.collection_path('123', collection: { members: 'remove' },
                                                                            batch_document_ids: ['456'])
    end
  end

  describe '#collection_options_for_select' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end
    let(:user) { create(:user) }
    let!(:collection1) { create(:collection, user: user, title: ['One']) }
    let!(:collection2) { create(:collection, user: user, title: ['Two']) }
    let!(:collection3) { create(:collection, user: user, title: ['Three']) }
    subject { helper.collection_options_for_select(collection2) }

    it 'excludes the passed in collection' do
      expect(subject).to eq "<option value=\"#{collection1.id}\">One</option>\n<option value=\"#{collection3.id}\">Three</option>"
    end
  end
end
