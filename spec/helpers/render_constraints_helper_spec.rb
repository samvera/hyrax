require 'spec_helper'

describe CurationConcernsHelper do
  let(:search_params) do
    ActionController::Parameters.new(q: 'Simon',
                                     search_field: 'publisher',
                                     controller: 'catalog')
  end
  describe 'render_constraints_query' do
    before do
      # Stub methods from Blacklight::SearchFields
      allow(helper).to receive(:default_search_field).and_return(CatalogController.blacklight_config.default_search_field)
      allow(helper).to receive(:label_for_search_field).and_return('Foo')
    end

    subject { helper.render_constraints_query(search_params) }

    it 'removes search_field' do
      node = Capybara::Node::Simple.new(subject)
      expect(node).to have_link 'Remove constraint Foo: Simon', href: search_catalog_path
    end

    it 'calls remove_constraint_url' do
      expect(helper).to receive(:remove_constraint_url).and_return('/hello')
      expect(subject).to include 'href="/hello"'
    end
  end

  describe 'remove_constraint_url' do
    subject { helper.remove_constraint_url(search_params) }
    it 'calls fields_to_exclude_from_constraint_element' do
      expect(helper).to receive(:fields_to_exclude_from_constraint_element).and_return([])
      expect(subject).to eq "/catalog?search_field=publisher"
    end
  end

  describe 'fields_to_exclude_from_constraint_element' do
    subject { helper.fields_to_exclude_from_constraint_element }
    it { is_expected.to eq [:search_field] }
  end
end
