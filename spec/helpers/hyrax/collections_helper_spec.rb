RSpec.describe Hyrax::CollectionsHelper do
  before do
    # Stub route because helper specs don't handle engine routes
    # https://github.com/rspec/rspec-rails/issues/1250
    allow(view).to receive(:collection_path) do |collection|
      id = collection.respond_to?(:id) ? collection.id : collection
      "/collections/#{id}"
    end
  end

  describe '#render_collection_links' do
    let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork']) }

    context 'when a GenericWork does not belongs to any collections', :clean_repo do
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

  describe "has_collection_search_parameters?" do
    subject { helper }

    context "when cq is set" do
      before { allow(helper).to receive(:params).and_return(cq: 'foo') }
      it { is_expected.to have_collection_search_parameters }
    end

    context "when cq is not set" do
      before { allow(helper).to receive(:params).and_return(cq: '') }
      it { is_expected.not_to have_collection_search_parameters }
    end
  end

  describe "button_for_remove_from_collection" do
    let(:item) { double(id: 'changeme:123') }
    let(:collection) { create(:collection) }

    it "generates a form that can remove the item" do
      str = button_for_remove_from_collection collection, item
      doc = Nokogiri::HTML(str)
      form = doc.xpath('//form').first
      expect(form.attr('action')).to eq hyrax.dashboard_collection_path(collection)
      expect(form.css('input#collection_members[type="hidden"][value="remove"]')).not_to be_empty
      expect(form.css('input[type="hidden"][name="batch_document_ids[]"][value="changeme:123"]')).not_to be_empty
    end

    describe "for a collection of another name" do
      before do
        class OtherCollection < ActiveFedora::Base
          include Hyrax::CollectionBehavior
          include Hydra::Works::WorkBehavior
        end
      end

      let!(:collection) { OtherCollection.create!(title: ['foo']) }

      after do
        Object.send(:remove_const, :OtherCollection)
      end

      it "generates a form that can remove the item" do
        str = button_for_remove_from_collection collection, item
        doc = Nokogiri::HTML(str)
        form = doc.xpath('//form').first
        expect(form.attr('action')).to eq hyrax.dashboard_collection_path(collection)
        expect(form.css('input#collection_members[type="hidden"][value="remove"]')).not_to be_empty
        expect(form.css('input[type="hidden"][name="batch_document_ids[]"][value="changeme:123"]')).not_to be_empty
      end
    end
  end

  describe "button_for_remove_selected_from_collection" do
    let(:collection) { create(:collection) }

    it "creates a button to the collections delete path" do
      str = button_for_remove_selected_from_collection collection
      doc = Nokogiri::HTML(str)
      form = doc.xpath('//form').first
      expect(form.attr('action')).to eq hyrax.dashboard_collection_path(collection)
      i = form.xpath('.//input')[2]
      expect(i.attr('value')).to eq("remove")
      expect(i.attr('name')).to eq("collection[members]")
    end

    it "creates a button with my text" do
      str = button_for_remove_selected_from_collection collection, "Remove My Button"
      doc = Nokogiri::HTML(str)
      form = doc.css('form').first
      expect(form.attr('action')).to eq hyrax.dashboard_collection_path(collection)
      expect(form.css('input[type="submit"]').attr('value').value).to eq "Remove My Button"
    end
  end
end
