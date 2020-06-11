# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form_for_select_collection.html.erb', type: :view do
  let(:collections) do
    [
      { id: 1234, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:20:22 +0100') },
      { id: 1235, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:18:22 +0100') },
      { id: 1236, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:16:22 +0100') },
      { id: 1237, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:29:22 +0100') }
    ]
  end
  let(:solr_collections) do
    collections.map do |c|
      doc = { id: c[:id],
              "has_model_ssim" => ["Collection"],
              "title_tesim" => ["Title 1"],
              "system_create_dtsi" => c[:create_date].to_s }
      SolrDocument.new(doc)
    end
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:collection_path).and_return("/collection/123")
    allow(view).to receive(:new_dashboard_collection_path).and_return("/collection/new")

    allow(view).to receive(:user_collections).and_return(solr_collections)
  end

  it "uses autocomplete" do
    render
    expect(page).to have_selector('input[data-autocomplete-url="/authorities/search/collections?access=deposit"]')
  end

  context 'when a collection is specified' do
    let(:collection_id) { collections[2][:id] }
    let(:collection_label) { collections[2]["title_tesim"] }

    it "selects the right collection when instructed to do so" do
      assign(:add_works_to_collection, collection_id)
      assign(:add_works_to_collection_label, collection_label)
      render
      expect(page).to have_selector "#member_of_collection_ids[value=\"#{collection_id}\"]", visible: false
      expect(page).to have_selector "#member_of_collection_label", text: collection_label
    end
  end
end
