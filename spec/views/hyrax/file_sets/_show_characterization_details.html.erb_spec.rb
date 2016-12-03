require 'spec_helper'

describe 'hyrax/file_sets/_show_characterization_details.html.erb', type: :view do
  let(:file) { build(:file_set).tap { |f| f.apply_depositor_metadata("user") } }
  let(:solr_document) { SolrDocument.new(file.to_solr) }
  let(:ability) { double "Ability" }
  let(:presenter) { Hyrax::FileSetPresenter.new(solr_document, ability) }
  let(:mock_metadata) do
    {
      format: ["Tape"],
      long_term: ["x" * 255],
      multi_term: ["1", "2", "3", "4", "5", "6", "7", "8"],
      string_term: 'oops, I used a string instead of an array'
    }
  end

  before do
    allow(presenter).to receive(:characterization_metadata).and_return(mock_metadata)
    assign(:presenter, presenter)
    render
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it 'displays characterization terms' do
    expect(page).to have_content("oops, I used a string instead of an array")
    expect(page).to have_content("xxxxxxx...")
    expect(page).to have_content("Format: Tape")
    expect(page).to have_css("div.modal")
    expect(page).to have_css("div.modal-body")
    expect(page).to have_css("h2#extraFieldsModal_multi_term_Label")
  end
end
