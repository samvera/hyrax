require 'spec_helper'

describe CurationConcerns::CollectionsHelper do
  describe "#link_to_select_collection" do
    let(:collection) { double(id: '123') }
    let(:collectible) { double(id: '456', human_readable_type: 'Generic Work', to_param: '456') }
    before do
      assign(:collection, collection)
    end
    subject { helper.link_to_select_collection(collectible) }

    it "has a link that pops up a modal" do
      expect(subject).to have_selector 'a[data-toggle=modal][data-target="#456-modal"]'
      expect(subject).to have_link 'Add to a Collection', href: '#'
    end
  end

  describe "#link_to_remove_from_collection" do
    let(:collection) { double(id: '123') }
    let(:collectible) { double(id: '456') }
    before do
      assign(:collection, collection)
    end
    subject { helper.link_to_remove_from_collection(collectible) }

    it "has a form that routes to remove the collectible" do
      expect(subject).to have_selector 'a[data-method=put]'
      expect(subject).to have_link 'Remove From Collection',
        href: collections.collection_path('123', collection: { members: 'remove'},
                                          batch_document_ids: [ '456' ])
    end
  end

end
