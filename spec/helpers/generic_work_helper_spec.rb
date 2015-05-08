require 'spec_helper'

describe GenericWorkHelper do

  describe '#render_collection_links' do
    let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], collection_ids_tesim: coll_ids) }

    context 'when a GenericWork does not belongs to any collections' do
      let(:coll_ids) { nil }

      it 'renders nothing' do
        expect(helper.render_collection_links(work_doc)).to be_nil
      end
    end

    context 'when a GenericWork belongs to collections' do
      let(:coll_1) { FactoryGirl.create(:collection, title: 'Collection 111') }
      let(:coll_2) { FactoryGirl.create(:collection, title: 'Collection 222') }
      let(:coll_ids) { [coll_1.id, coll_2.id] }

      before do
        coll_1.update_index
      end

      it 'renders a list of links to the collections' do
        expect(helper.render_collection_links(work_doc)).to match /Is part of/

        expect(helper.render_collection_links(work_doc)).to match "href=\"/collections/#{coll_1.id}\""
        expect(helper.render_collection_links(work_doc)).to match "href=\"/collections/#{coll_2.id}\""

        expect(helper.render_collection_links(work_doc)).to match coll_1.title
        expect(helper.render_collection_links(work_doc)).to match coll_2.title
      end
    end
  end

end
