describe 'collections/_form_for_select_collection.html.erb', type: :view do
  let(:collections) do
    [
      build(:collection, id: '1234', create_date: Time.zone.parse('Thu, 13 Aug 2015 14:20:22 +0100')),
      build(:collection, id: '1235', create_date: Time.zone.parse('Thu, 13 Aug 2015 14:18:22 +0100')),
      build(:collection, id: '1236', create_date: Time.zone.parse('Thu, 13 Aug 2015 14:16:22 +0100')),
      build(:collection, id: '1237', create_date: Time.zone.parse('Thu, 13 Aug 2015 14:29:22 +0100'))
    ]
  end
  let(:solr_collections) do
    collections.map do |c|
      SolrDocument.new(c.to_solr.merge('system_create_dtsi' => c.create_date.to_s))
    end
  end

  let(:doc) { Nokogiri::HTML(rendered) }

  before { allow(view).to receive(:user_collections).and_return(solr_collections) }

  it "sorts the collections" do
    render
    collection_ids = doc.xpath("//input[@class='collection-selector']/@id").map(&:to_s)
    expect(collection_ids).to eql(["id_1237", "id_1234", "id_1235", "id_1236"])
    expect(rendered).to have_selector("label", text: collections.first.title.first)
    expect(rendered).not_to have_selector("label", text: "[\"#{collections.first.title.first}\"]")
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
