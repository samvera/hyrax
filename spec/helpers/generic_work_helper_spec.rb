describe GenericWorkHelper do
  describe '#render_collection_links' do
    let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork']) }

    context 'when a GenericWork does not belongs to any collections' do
      it 'renders nothing' do
        expect(helper.render_collection_links(work_doc)).to be_nil
      end
    end

    context 'when a GenericWork belongs to collections' do
      let(:coll_ids) { ['111', '222'] }
      let(:coll_titles) { ['Collection 111', 'Collection 222'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]], child_object_ids_ssim: [work_doc.id] } }
      let(:coll2_attrs) { { id: coll_ids[1], title_tesim: [coll_titles[1]], child_object_ids_ssim: [work_doc.id, 'abc123'] } }
      before do
        ActiveFedora::SolrService.add(coll1_attrs)
        ActiveFedora::SolrService.add(coll2_attrs)
        ActiveFedora::SolrService.commit
      end

      it 'renders a list of links to the collections' do
        expect(helper.render_collection_links(work_doc)).to match(/Is part of/i)

        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[0]}\"")
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[1]}\"")

        expect(helper.render_collection_links(work_doc)).to match(coll_titles[0])
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[1])
      end
    end
  end
end
