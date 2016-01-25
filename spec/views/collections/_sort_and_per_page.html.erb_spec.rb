require 'spec_helper'

describe 'collections/_sort_and_per_page.html.erb' do
  let(:collection) { double }
  let(:response) { double(response: { 'numFound' => 3 }) }
  let(:search_state) { double('SearchState', params_for_search: {}) }

  before do
    allow(view).to receive(:search_state).and_return(search_state)
    allow(view).to receive(:sort_fields).and_return(['title_sort', 'date_sort'])
    allow(view).to receive(:document_index_views).and_return(list: Blacklight::Configuration::ViewConfig.new)
    assign(:response, response)
  end

  context "when the action is edit" do
    before do
      controller.action_name = "edit"
    end
    it "renders the form with a button" do
      expect(view).to receive(:button_for_remove_selected_from_collection).with(collection)
      render 'collections/sort_and_per_page', collection: collection
    end
  end

  context "when the action is show" do
    before do
      controller.action_name = "show"
    end
    it "renders the form without a button" do
      expect(view).not_to receive(:button_for_remove_selected_from_collection)
      render 'collections/sort_and_per_page', collection: collection
    end
  end
end
