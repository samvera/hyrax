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
    let(:doc1) { SolrDocument.new("id" => "k930bx31t", "title_tesim" => ["One"]) }
    let(:doc2) { SolrDocument.new("id" => "02870w10j", "title_tesim" => ["Two"]) }
    let(:doc3) { SolrDocument.new("id" => "z029p500w", "title_tesim" => ["Three"]) }
    let(:service) { instance_double(CurationConcerns::CollectionsService) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(CurationConcerns::CollectionsService).to receive(:new).with(controller).and_return(service)
      expect(service).to receive(:search_results).with(:edit).and_return([doc1, doc2, doc3])
    end

    subject { helper.collection_options_for_select(collection2) }

    it 'excludes the passed in collection' do
      expect(subject).to eq "<option value=\"#{doc1.id}\">One</option>\n<option value=\"#{doc3.id}\">Three</option>"
    end

    context "when one of the documents doesn't have title_tesim" do
      let(:doc1) { SolrDocument.new("id" => "k930bx31t") }
      it 'puts the collections without titles last' do
        expect(subject).to eq "<option value=\"#{doc3.id}\">Three</option>\n<option value=\"#{doc1.id}\"></option>"
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
    let(:collection) { FactoryGirl.create(:collection) }

    it "generates a form that can remove the item" do
      str = button_for_remove_from_collection collection, item
      doc = Nokogiri::HTML(str)
      form = doc.xpath('//form').first
      expect(form.attr('action')).to eq collection_path(collection)
      expect(form.css('input#collection_members[type="hidden"][value="remove"]')).not_to be_empty
      expect(form.css('input[type="hidden"][name="batch_document_ids[]"][value="changeme:123"]')).not_to be_empty
    end

    describe "for a collection of another name" do
      before(:all) do
        class OtherCollection < ActiveFedora::Base
          include CurationConcerns::Collection
          include Hydra::Works::WorkBehavior
        end
      end

      let!(:collection) { OtherCollection.create! }

      after(:all) do
        Object.send(:remove_const, :OtherCollection)
      end

      it "generates a form that can remove the item" do
        str = button_for_remove_from_collection collection, item
        doc = Nokogiri::HTML(str)
        form = doc.xpath('//form').first
        expect(form.attr('action')).to eq collection_path(collection)
        expect(form.css('input#collection_members[type="hidden"][value="remove"]')).not_to be_empty
        expect(form.css('input[type="hidden"][name="batch_document_ids[]"][value="changeme:123"]')).not_to be_empty
      end
    end
  end

  describe "button_for_remove_selected_from_collection" do
    let(:collection) { FactoryGirl.create(:collection) }

    it "creates a button to the collections delete path" do
      str = button_for_remove_selected_from_collection collection
      doc = Nokogiri::HTML(str)
      form = doc.xpath('//form').first
      expect(form.attr('action')).to eq collection_path(collection)
      i = form.xpath('.//input')[2]
      expect(i.attr('value')).to eq("remove")
      expect(i.attr('name')).to eq("collection[members]")
    end

    it "creates a button with my text" do
      str = button_for_remove_selected_from_collection collection, "Remove My Button"
      doc = Nokogiri::HTML(str)
      form = doc.css('form').first
      expect(form.attr('action')).to eq collection_path(collection)
      expect(form.css('input[type="submit"]').attr('value').value).to eq "Remove My Button"
    end
  end

  describe "hidden_collection_members" do
    before { helper.params[:batch_document_ids] = ['foo:12', 'foo:23'] }
    it "makes hidden fields" do
      doc = Nokogiri::HTML(hidden_collection_members)
      inputs = doc.xpath('//input[@type="hidden"][@name="batch_document_ids[]"]')
      expect(inputs.length).to eq(2)
      expect(inputs[0].attr('value')).to eq('foo:12')
      expect(inputs[1].attr('value')).to eq('foo:23')
    end
  end
end
