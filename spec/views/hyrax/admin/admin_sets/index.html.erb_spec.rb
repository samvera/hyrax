# frozen_string_literal: true
require "spec_helper"

RSpec.describe "hyrax/admin/admin_sets/index.html.erb", type: :view do
  before do
    allow(controller).to receive(:can?).with(:create, AdminSet).and_return(false)
    allow(Flipflop).to receive(:read_only?).and_return(false)
  end

  context "when no admin sets exists" do
    it "alerts users there are no admin sets" do
      render
      expect(rendered).to have_content("No administrative sets have been created.")
    end
  end

  context "when an admin set exists" do
    let(:solr_doc) do
      SolrDocument.new(has_model_ssim: 'AdminSet',
                       id: 123,
                       title_tesim: ['Example Admin Set'],
                       creator_ssim: ['jdoe@example.com'])
    end
    let(:admin_sets) { [solr_doc] }
    let(:presenter_class) { Hyrax::AdminSetPresenter }
    let(:presenter) { instance_double(presenter_class, total_items: 99) }
    let(:ability) { instance_double("Ability") }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(controller).to receive(:presenter_class).and_return(presenter_class)
      allow(presenter_class).to receive(:new).and_return(presenter)
      assign(:admin_sets, admin_sets)
    end
    it "lists admin set" do
      render
      expect(rendered).to have_content('Example Admin Set')
      expect(rendered).to have_content('jdoe@example.com')
      expect(rendered).to have_css("td", text: /^99$/)
    end
  end
end
