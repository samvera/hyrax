require 'spec_helper'

describe 'curation_concerns/base/relationships', type: :view do
  let(:ability) { double }
  let(:solr_doc) { double(id: '123', human_readable_type: 'Work') }
  let(:presenter) { Sufia::WorkShowPresenter.new(solr_doc, ability) }

  context "when collections are not present" do
    before do
      render 'curation_concerns/base/relationships', presenter: presenter
    end
    it "shows the message" do
      expect(rendered).to match %r{This Work is not currently in any collections\.}
    end
  end

  context "when collections are present" do
    let(:collection_presenters) { [double(id: '456', title: ['Containing collection', 'foobar'], to_s: 'Containing collection')] }
    let(:page) { Capybara::Node::Simple.new(rendered) }
    before do
      allow(presenter).to receive(:collection_presenters).and_return(collection_presenters)
      render 'curation_concerns/base/relationships', presenter: presenter
    end
    it "links to collections" do
      expect(page).to have_link 'Containing collection'
    end
    it "labels the link using the presenter's #to_s method" do
      expect(page).not_to have_content 'foobar'
    end
  end
end
