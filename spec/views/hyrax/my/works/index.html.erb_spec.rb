# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'hyrax/my/works/index.html.erb', type: :view do
  let(:presenter) { instance_double(Hyrax::SelectTypeListPresenter, many?: true) }

  before do
    allow(view).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:provide).and_yield
    allow(view).to receive(:provide).with(:page_title, String)
    allow(view).to receive(:create_work_presenter).and_return(presenter)
    allow(view).to receive(:can?).and_return(true)
    stub_template 'hyrax/my/works/_tabs.html.erb' => 'tabs'
    stub_template 'hyrax/my/works/_search_header.html.erb' => 'search'
    stub_template 'hyrax/my/works/_document_list.html.erb' => 'list'
    stub_template 'hyrax/my/works/_results_pagination.html.erb' => 'pagination'
    stub_template 'hyrax/my/works/_scripts.js.erb' => 'batch edit stuff'
    render
  end

  context "when the user can add works" do
    let(:ability) { instance_double(Ability, can_create_any_work?: true) }
    it 'the line item displays the work and its actions' do
      expect(rendered).to have_selector('h1', text: 'Works')
      expect(rendered).to have_link('Create batch of works')
      expect(rendered).to have_link('Add new work')
    end
  end
end
