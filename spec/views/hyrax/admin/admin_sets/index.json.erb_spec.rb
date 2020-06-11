# frozen_string_literal: true
RSpec.describe "hyrax/admin/admin_sets/index.json.jbuilder" do
  context "when no admin sets exists" do
    it "renders no admin sets" do
      render
      json = JSON.parse(rendered)
      expect(json['admin_sets']).to eq []
    end
  end

  context "when an admin set exists" do
    let(:solr_doc) { SolrDocument.new(id: '123', title_tesim: ['Example Admin Set'], description_tesim: ['Wat']) }
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
      json = JSON.parse(rendered)
      expect(json['admin_sets']).to eq [{ 'id' => '123', 'title' => ['Example Admin Set'], 'description' => ['Wat'] }]
    end
  end
end
