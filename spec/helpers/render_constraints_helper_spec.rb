require 'spec_helper'

describe CurationConcernsHelper do
  describe "render_constraints_query" do
    before do
      # Stub methods from Blacklight::SearchFields
      allow(helper).to receive(:default_search_field).and_return(CatalogController.blacklight_config.default_search_field)
      allow(helper).to receive(:label_for_search_field).and_return("Foo")
    end

    let(:search_params) { { q: 'Simon', search_field: 'publisher', controller: 'catalog' } }
    subject { helper.render_constraints_query(search_params) }

    it "removes search_field" do
      node = Capybara::Node::Simple.new(subject)
      expect(node).to have_link 'Remove constraint Foo: Simon', href: '/'
    end
  end
end
