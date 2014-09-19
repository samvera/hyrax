require 'spec_helper'

describe Worthwhile::CollectionsHelper do
  describe "#link_to_remove_from_collection" do
    let(:collection) { double(id: '123') }
    let(:collectible) { double(id: '456') }
    before do
      assign(:collection, collection)
    end
    subject { helper.link_to_remove_from_collection(collectible) }

    it "should have a form that routes to remove the collectible" do
      expect(subject).to have_selector 'a[data-method=put]'
      expect(subject).to have_link 'Remove From Collection',
        href: collections.collection_path('123', collection: { members: 'remove'},
                                          batch_document_ids: [ '456' ])
    end
  end
end
