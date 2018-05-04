RSpec.describe Hyrax::CollectionsHelper do
  let(:user) { create(:user, groups: ['admin']) }
  let(:ability) { Ability.new(user) }

  before do
    # Stub route because helper specs don't handle engine routes
    # https://github.com/rspec/rspec-rails/issues/1250
    allow(view).to receive(:collection_path) do |collection|
      id = collection.respond_to?(:id) ? collection.id : collection
      "/collections/#{id}"
    end
  end

  describe '#render_collection_links' do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when a GenericWork does not belongs to any collections', :clean_repo do
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork']) }

      it 'renders nothing' do
        expect(helper.render_collection_links(work_doc)).to be_nil
      end
    end

    context 'when a GenericWork belongs to collections' do
      let(:coll_ids) { ['111', '222'] }
      let(:coll_titles) { ['Collection 111', 'Collection 222'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]] } }
      let(:coll2_attrs) { { id: coll_ids[1], title_tesim: [coll_titles[1]] } }
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], member_of_collection_ids_ssim: coll_ids) }

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

  describe "collection_type_label" do
    context "when the CollectionType is found" do
      let(:test_collection_type) { FactoryBot.create(:collection_type) }

      it "returns the CollectionType title" do
        expect(collection_type_label(test_collection_type.gid)).to eq test_collection_type.title
      end
    end

    context "when the CollectionType cannot be found" do
      it "returns the input gid unchanged" do
        expect(collection_type_label(nil)).to eq "User Collection"
      end
    end
  end

  describe '#append_collection_type_url' do
    let(:url) { "http://example.com" }
    context "when a provided url has no querystring" do
      it 'returns the url with added collection_type_id' do
        expect(append_collection_type_url(url, '1')).to eq "#{url}?collection_type_id=1"
      end
    end

    context "when a provided url has an existing querystring" do
      let(:url) { "http://example.com?bob=ross" }
      it 'return the url with added collection_type_id' do
        expect(append_collection_type_url(url, '1')).to eq "#{url}&collection_type_id=1"
      end
    end
  end
end
