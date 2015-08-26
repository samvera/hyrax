require 'spec_helper'

describe 'collections/_form_for_select_collection.html.erb' do
  let(:collections) {
    [
      Collection.new(id: '1234', title: 'collection 1', create_date: DateTime.parse('Thu, 13 Aug 2015 14:20:22 +0100')),
      Collection.new(id: '1235', title: 'collection 2', create_date: DateTime.parse('Thu, 13 Aug 2015 14:18:22 +0100')),
      Collection.new(id: '1236', title: 'collection 3', create_date: DateTime.parse('Thu, 13 Aug 2015 14:16:22 +0100')),
      Collection.new(id: '1237', title: 'collection 4', create_date: DateTime.parse('Thu, 13 Aug 2015 14:29:22 +0100'))
    ]
  }
  let(:solr_collections) {
    collections.map do |c|
      SolrDocument.new(c.to_solr).tap do |sd|
        sd['system_create_dtsi'] = c.create_date.to_s
      end
    end
  }

  let(:doc) {
    Nokogiri::HTML(rendered)
  }

  before do
    allow(view).to receive(:user_collections).and_return(solr_collections)
  end

  it "sorts the collections" do
    render
    collection_ids = doc.xpath("//input[@class='collection-selector']/@id").map(&:to_s)
    expect(collection_ids).to eql(["id_1237", "id_1234", "id_1235", "id_1236"])
  end

  it "selects the right collection when instructed to do so" do
    assign(:add_files_to_collection, collections[2].id)
    render
    expect(rendered).not_to have_selector "#id_#{collections[0].id}[checked='checked']"
    expect(rendered).not_to have_selector "#id_#{collections[1].id}[checked='checked']"
    expect(rendered).not_to have_selector "#id_#{collections[3].id}[checked='checked']"
    expect(rendered).to have_selector "#id_#{collections[2].id}[checked='checked']"
  end

  it "selects the first collection when nothing else specified" do
    # first when sorted by create date, so not index 0
    render
    expect(rendered).not_to have_selector "#id_#{collections[0].id}[checked='checked']"
    expect(rendered).not_to have_selector "#id_#{collections[1].id}[checked='checked']"
    expect(rendered).not_to have_selector "#id_#{collections[2].id}[checked='checked']"
    expect(rendered).to have_selector "#id_#{collections[3].id}[checked='checked']"
  end
end
